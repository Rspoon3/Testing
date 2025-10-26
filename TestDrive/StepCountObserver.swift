//
//  StepCountObserver.swift
//  TestDrive
//
//  Created by Claude on 10/26/25.
//

import Foundation
import HealthKit
import UserNotifications

/// Observes HealthKit for step count updates and sends daily step count notifications
struct StepCountObserver {
    private let healthStore = HKHealthStore()

    // MARK: - Public Helpers

    /// Enables background delivery and starts observing step count
    /// Must be called from application(_:didFinishLaunchingWithOptions:)
    func startObserving() async {
        #if DEBUG
        await sendInfoNotification(title: "Step Observer Started", message: "Observing for step count updates...")
        #endif

        await enableBackgroundDelivery()
        await observeSteps()
    }

    // MARK: - Private Helpers

    /// Enables background delivery for step count updates
    private func enableBackgroundDelivery() async {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }

        do {
            try await healthStore.enableBackgroundDelivery(for: stepType, frequency: .hourly)
        } catch {
            print("Failed to enable background delivery for steps: \(error)")
            #if DEBUG
            await sendErrorNotification(title: "Background Delivery Failed", message: error.localizedDescription)
            #endif
        }
    }

    /// Observes step count updates using AsyncStream
    private func observeSteps() async {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }

        let stream = HKObserverQuery.stream(
            sampleType: stepType,
            predicate: nil,
            healthStore: healthStore
        )

        for await _ in stream {
            await fetchDailyStepCountAndNotify()
        }
    }

    /// Fetches today's step count and sends a notification
    private func fetchDailyStepCountAndNotify() async {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: .now)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? .now

        let predicate = HKQuery.predicateForSamples(
            withStart: startOfDay,
            end: endOfDay,
            options: .strictStartDate
        )

        let stepDescriptor = HKSampleQueryDescriptor(
            predicates: [.quantitySample(type: stepType, predicate: predicate)],
            sortDescriptors: [SortDescriptor(\.startDate, order: .forward)]
        )

        do {
            let samples = try await stepDescriptor.result(for: healthStore)
            let totalSteps = samples
                .compactMap { $0 as? HKQuantitySample }
                .map { $0.quantity.doubleValue(for: HKUnit.count()) }
                .reduce(0, +)

            let stepCount = Int(totalSteps)

            #if DEBUG
            await sendStepCountNotification(stepCount: stepCount)
            #endif
        } catch {
            print("Failed to fetch step count: \(error)")
            #if DEBUG
            await sendErrorNotification(title: "Step Count Fetch Failed", message: error.localizedDescription)
            #endif
        }
    }

    #if DEBUG
    /// Sends a notification with the current step count
    /// - Parameter stepCount: The total step count for today
    private func sendStepCountNotification(stepCount: Int) async {
        let content = UNMutableNotificationContent()
        content.title = "📊 Daily Step Count"
        content.body = "You've taken \(stepCount.formatted()) steps today!"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Failed to send step count notification: \(error)")
        }
    }

    /// Sends an error notification for debugging
    /// - Parameters:
    ///   - title: The notification title
    ///   - message: The error message
    private func sendErrorNotification(title: String, message: String) async {
        let content = UNMutableNotificationContent()
        content.title = "⚠️ \(title)"
        content.body = message
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Failed to send error notification: \(error)")
        }
    }

    /// Sends an info notification for debugging
    /// - Parameters:
    ///   - title: The notification title
    ///   - message: The info message
    private func sendInfoNotification(title: String, message: String) async {
        let content = UNMutableNotificationContent()
        content.title = "ℹ️ \(title)"
        content.body = message
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            print("Failed to send info notification: \(error)")
        }
    }
    #endif
}
