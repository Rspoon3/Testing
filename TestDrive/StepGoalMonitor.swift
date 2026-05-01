//
//  StepGoalMonitor.swift
//  Testing
//
//  Created by Ricky Witherspoon on 4/13/25.
//

import HealthKit
import UserNotifications

final class StepGoalMonitor {
    private let healthStore = HKHealthStore()
    private let stepType = HKObjectType.quantityType(forIdentifier: .stepCount)!
    private var queryAnchor: HKQueryAnchor? // You should persist this between launches
    private let userNotificationCenter = UNUserNotificationCenter.current()
    
    // MARK: - Public

    func requestNotifications() async throws {
        let granted = try await userNotificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
        print(granted ? "🔔 Notification permission granted" : "🚫 Notification permission denied")
    }

    func startMonitoring() {
        print("📡 Starting step count monitoring...")

        // 1. Enable background delivery
        healthStore.enableBackgroundDelivery(for: stepType, frequency: .immediate) { success, error in
            if success {
                print("✅ Background delivery enabled for step count")
            } else {
                print("❌ Failed to enable background delivery: \(error?.localizedDescription ?? "Unknown error")")
            }
        }

        // 2. Create anchored object query
        let query = HKAnchoredObjectQuery(type: stepType, predicate: nil,
                                          anchor: queryAnchor, limit: HKObjectQueryNoLimit) {
            [weak self] query, newSamples, deletedSamples, newAnchor, error in
            print("📥 Received initial step samples")
            self?.process(newSamples, newAnchor: newAnchor)
        }

        // 3. Set update handler
        query.updateHandler = { [weak self] query, newSamples, deletedSamples, newAnchor, error in
            print("🔄 Step data updated via updateHandler")
            self?.process(newSamples, newAnchor: newAnchor)
        }

        // 4. Execute query
        print("🚀 Executing step count anchored query")
        healthStore.execute(query)
    }

    // MARK: - Private

    private func process(_ newSamples: [HKSample]?, newAnchor: HKQueryAnchor?) {
        guard let samples = newSamples as? [HKQuantitySample] else {
            print("⚠️ No valid quantity samples to process")
            return
        }

        // Save the new anchor for persistence
        self.queryAnchor = newAnchor
        print("📌 Query anchor updated")

        // Sum new step count delta
        let stepCountDelta = samples.reduce(0.0) { $0 + $1.quantity.doubleValue(for: .count()) }
        print("📊 Step delta from new samples: \(Int(stepCountDelta))")

        if stepCountDelta == 0 {
            print("⏭️ No new steps since last update")
            return
        }

        // Fetch total step count for the day
        let startOfDay = Calendar.current.startOfDay(for: Date())
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: Date(), options: .strictEndDate)

        let statsQuery = HKStatisticsQuery(quantityType: stepType,
                                           quantitySamplePredicate: predicate,
                                           options: .cumulativeSum) { [weak self] _, statistics, _ in
            let totalSteps = statistics?.sumQuantity()?.doubleValue(for: .count()) ?? 0
            print("📈 Total steps today: \(Int(totalSteps))")

            self?.handleStepGoalReached(totalSteps: Int(totalSteps))
        }

        print("📤 Executing cumulative statistics query for daily steps")
        healthStore.execute(statsQuery)
    }

    private func handleStepGoalReached(totalSteps: Int) {
        print("🏁 Step goal handler triggered — steps: \(totalSteps)")
        // Here you can call a shield unblocking function, etc.
        scheduleCongratulationsNotification(totalSteps: totalSteps)
    }

    private func scheduleCongratulationsNotification(totalSteps: Int) {
        Task {
            let content = UNMutableNotificationContent()
            let formattedSteps = totalSteps.formatted()
            content.title = "\(formattedSteps) Steps!"
            content.body = "Congrats, you've walked \(formattedSteps) steps today and hit your goal."
            content.sound = .default

            do {
                let request = UNNotificationRequest(identifier: "StepGoalReached", content: content, trigger: nil)
                try await userNotificationCenter.add(request)
                print("📨 Scheduled local notification for \(formattedSteps) steps")
            } catch {
                print("❌ Failed to schedule notification: \(error)")
            }
        }
    }
}
