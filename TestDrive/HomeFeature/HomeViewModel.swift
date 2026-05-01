//
//  HomeViewModel.swift
//  Testing
//
//  Created by Ricky Witherspoon on 4/15/25.
//

import SwiftUI
import HealthKit
import FamilyControls
import ManagedSettings
import DeviceActivity
import OSLog
import SwiftTools
import Solar

/// The main observable view model for managing health goals, blocking logic, and user preferences.
@MainActor
@Observable
final class HomeViewModel {
    
    // MARK: - Dependencies
    
    /// Logger instance scoped to this view model.
    private let logger = Logger(category: HomeViewModel.self)
    
    /// HealthKit manager for retrieving activity data.
    private let healthKitManager = HealthKitManager()
    
    /// Shared UserDefaults instance for persistent storage.
    private let userDefaults = UserDefaults.shared
    
    /// Settings store for managing app blocking/shielding.
    private let managedSettingsStore = ManagedSettingsStore()
    
    /// Device Activity Center used to monitor daily activity.
    private let center = DeviceActivityCenter()
    
    // MARK: - State
    
    /// Current health metrics, such as step count and mindfulness minutes.
    private(set) var metrics = HealthKitMetrics()
    
    /// Application tokens that are saved for shielding/unshielding.
    private(set) var savedAppTokens: Set<ApplicationToken> = []

    /// Controls presentation of the app picker.
    var showPicker = false
    
    /// The currently selected apps for monitoring and shielding.
    var familyActivitySelection = FamilyActivitySelection(includeEntireCategory: true) {
        didSet {
            saveActivitySelection(familyActivitySelection)
            self.savedAppTokens = familyActivitySelection.applicationTokens

            Task {
                try? await evaluateProgressAndShieldApps()
            }
        }
    }
    
    /// User-defined daily step goal.
    var stepGoal: Int {
        didSet {
            userDefaults.set(stepGoal, forKey: "stepGoal")
            Task {
                try? await evaluateProgressAndShieldApps()
            }
        }
    }
    
    /// User-defined daily mindfulness goal (in minutes).
    var mindfulnessGoal: Int {
        didSet {
            userDefaults.set(mindfulnessGoal, forKey: "mindfulnessGoal")
            Task {
                try? await evaluateProgressAndShieldApps()
            }
        }
    }
    
    /// Selected goal types that determine blocking logic.
    var selectedBlockModes: Set<BlockMode> {
        didSet {
            let rawValues = selectedBlockModes.map { $0.rawValue }
            userDefaults.set(rawValues, forKey: "selectedBlockModes")
            Task {
                try? await evaluateProgressAndShieldApps()
            }
        }
    }
    
    /// User’s preferred skip option when opting out of a blocked session.
    private(set) var skipOption: SkipOption {
        didSet {
            userDefaults.set(skipOption.rawValue, forKey: "skipOption")
        }
    }
    
    // MARK: - Initialization
    
    /// Initializes the view model and loads stored preferences or defaults.
    init() {
        // Load selectedBlockModes
        if let rawValues = userDefaults.array(forKey: "selectedBlockModes") as? [Int] {
            let modes = rawValues.compactMap { BlockMode(rawValue: $0) }
            selectedBlockModes = Set(modes.isEmpty ? [.steps] : modes)
        } else {
            selectedBlockModes = [.steps, .mindfulness]
        }
        
        // Load skipOption
        if let raw = userDefaults.object(forKey: "skipOption") as? Int,
           let option = SkipOption(rawValue: raw) {
            skipOption = option
        } else {
            skipOption = .five
        }
        
        // Load goals
        self.stepGoal = userDefaults.integer(forKey: "stepGoal")
        self.mindfulnessGoal = userDefaults.integer(forKey: "mindfulnessGoal")
        
        // Apply defaults if unset
        if stepGoal == 0 { stepGoal = 10_000 }
        if mindfulnessGoal == 0 { mindfulnessGoal = 5 }
    }
    
    // MARK: - Public Helpers
    
    // Load activity selection
    func restoreFamilySelection() {
        guard let restored = loadActivitySelection() else { return }
        self.familyActivitySelection = restored
        self.savedAppTokens = restored.applicationTokens
    }
    
    /// Toggles a block mode on or off. If only one remains, it cannot be removed.
    /// - Parameter mode: The mode to toggle.
    func toggleBlockMode(_ mode: BlockMode) {
        withAnimation(.bouncy) {
            if selectedBlockModes.contains(mode) {
                guard selectedBlockModes.count > 1 else { return }
                selectedBlockModes.remove(mode)
            } else {
                selectedBlockModes.insert(mode)
            }
        }
    }
    
    func skipOptionSelected(_ option: SkipOption) async {
        switch option {
        case .sunset:
            let locationManager = LocationManager()
            let calendar = Calendar.current
            
            await locationManager.requestWhenInUseAuthorization()
            
            do {
                let coordinate = try await locationManager.currentLocation()
                let solar = Solar(coordinate: coordinate)
                
                guard
                    let sunsetUTC = solar?.sunset,
                    let sunsetLocalComponents = calendar.dateComponents(in: .current, from: sunsetUTC) as DateComponents?,
                    let localTime = calendar.date(from: sunsetLocalComponents),
                    let components = calendar.dateComponents([.hour, .minute], from: localTime) as DateComponents?,
                    let hour = components.hour,
                    let minute = components.minute
                else {
                    return
                }
                
                logger.info("Local Sunset Time: \(localTime.formatted())")
                print(hour, minute)

                let schedule = DeviceActivitySchedule(
                    intervalStart: DateComponents(hour: 0, minute: 0, second: 0),
                    intervalEnd: DateComponents(hour: hour, minute: minute, second: 0),
                    repeats: true
                )
                
                try center.startMonitoring(DeviceActivityName("DailyRingReset"), during: schedule)
                logger.debug("✅ Scheduled daily ring reset at \(hour):\(minute) local time")
                
                withAnimation(.bouncy) {
                    skipOption = option
                }
            } catch {
                logger.debug("❌ Failed to start monitoring: \(error)")
                return
            }
        default:
            withAnimation(.bouncy) {
                skipOption = option
            }
        }
    }
    
    
    /// Evaluates user progress and updates app shielding based on configured goals.
    func evaluateProgressAndShieldApps() async throws {
        try await fetchNeededHealthKitMetrics()
        scheduleDailyRingReset()
        changeBlockStatusIfNeeded()
    }
    
    // MARK: - Private
    
    /// Fetches step count, mindfulness minutes, and ring values as needed.
    private func fetchNeededHealthKitMetrics() async throws {
        metrics = try await withThrowingTaskGroup(of: HealthKitMetricResult.self) { group in
            var collected = HealthKitMetrics()
            
            if selectedBlockModes.contains(.steps) {
                group.addTask {
                    let count = try await self.healthKitManager.stepCount()
                    return .stepCount(count)
                }
            } else {
                metrics.stepCount = nil
            }
            
            if selectedBlockModes.contains(.mindfulness) {
                group.addTask {
                    let minutes = try await self.healthKitManager.mindfulnessMinutes()
                    return .mindfulnessMinutes(minutes)
                }
            } else {
                metrics.mindfulnessMinutes = nil
            }
            
            if selectedBlockModes.contains(.rings) {
                group.addTask {
                    let rings = try await self.healthKitManager.rings()
                    return .ringValues(rings)
                }
            } else {
                metrics.ringValues = nil
            }
            
            for try await result in group {
                switch result {
                case .stepCount(let count):
                    collected.stepCount = count
                case .mindfulnessMinutes(let minutes):
                    collected.mindfulnessMinutes = minutes
                case .ringValues(let values):
                    collected.ringValues = values
                }
            }
            
            return collected
        }
    }
    
    /// Sets up daily monitoring for ring reset.
    private func scheduleDailyRingReset() {
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0, second: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59, second: 59),
            repeats: true
        )
        
        do {
            try center.startMonitoring(DeviceActivityName("DailyRingReset"), during: schedule)
            logger.debug("✅ Scheduled daily app blocking reset")
        } catch {
            logger.debug("❌ Failed to start monitoring: \(error)")
        }
    }
    
    /// Determines whether apps should be shielded or unshielded based on current progress.
    private func changeBlockStatusIfNeeded() {
        let conditionsMet = selectedBlockModes.allSatisfy { mode in
            switch mode {
            case .mindfulness:
                return (metrics.mindfulnessMinutes ?? 0) >= mindfulnessGoal
            case .rings:
                return metrics.ringValues?.allClosed ?? false
            case .steps:
                return (metrics.stepCount ?? 0) >= stepGoal
            }
        }
        
        if conditionsMet {
            logger.debug("🎉 Goal met — unblocking apps")
            managedSettingsStore.shield.applications = nil
        } else {
            logger.debug("🔒 No goal met — applying shield")
            managedSettingsStore.shield.applications = savedAppTokens
        }
    }
    
    // MARK: - Persistence
    
    /// Saves the current app selection to `UserDefaults`.
    /// - Parameter selection: The current selection to be stored.
    private func saveActivitySelection(_ selection: FamilyActivitySelection) {
        do {
            let data = try JSONEncoder().encode(selection)
            UserDefaults.shared.set(data, forKey: "SavedActivitySelection")
        } catch {
            logger.debug("❌ Failed to encode selection: \(error)")
        }
    }
    
    /// Loads a previously saved app selection from `UserDefaults`.
    /// - Returns: A decoded `FamilyActivitySelection` if available.
    private func loadActivitySelection() -> FamilyActivitySelection? {
        guard let data = UserDefaults.shared.data(forKey: "SavedActivitySelection") else { return nil }
        
        do {
            return try JSONDecoder().decode(FamilyActivitySelection.self, from: data)
        } catch {
            logger.debug("❌ Failed to decode selection: \(error)")
            return nil
        }
    }
}
