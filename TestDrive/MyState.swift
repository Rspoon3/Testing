//
//  MyState.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 10/31/25.
//

import Foundation
import CaseDetectionMacro

// MARK: - Example: Nested Enum (Enum-in-Enum)

@CaseDetection
@CaseAssociatedValueDetection
enum UTSStatus {
    case unlocking(stepsComplete: Int, stepsTotal: Int)
    case locked
    case unlocked
}

@CaseDetection
@CaseAssociatedValueDetection
enum MyState {
    case connecting
    case messaging(message: String)
    case error(localizedDescription: String)
    case sent(date: Date, count: Int)
    case eligible(stepsComplete: Int, stepsTotal: Int)
    case status(utsStatus: UTSStatus)
    case test
}

// MARK: - Example Usage

final class Tester {
    let state: MyState = .connecting

    // MARK: - Quick Demo

    /// Demonstrates both CaseDetection and CaseAssociatedValueDetection macros
    func quickDemo() {
        
        switch state {
        case .connecting:
            fatalError()
        default: fatalError()
        }
        
        
        // CaseDetection - Boolean checks (one-liner)
        print("Is connecting: \(state.isConnecting)")
        print("Is error: \(state.isError)")
        print("Is sent: \(state.isSent)")

        // CaseAssociatedValueDetection - Optional access (one-liner)
        print("Message: \(state.messaging?.message ?? "none")")
        print("Error: \(state.error?.localizedDescription ?? "none")")
        print("Sent count: \(state.sent?.count ?? 0)")
        print("Progress: \(state.eligible.map { "\($0.stepsComplete)/\($0.stepsTotal)" } ?? "none")")
        print("Status locked: \(state.status?.utsStatus.isLocked ?? false)")
        print("Status unlocking: \(state.status?.utsStatus.unlocking.map { "\($0.stepsComplete)/\($0.stepsTotal)" } ?? "none")")
    }

    // MARK: - Basic Examples

    func basicUsage() {
        // Using CaseDetection macro - simple boolean check
        print(state.isConnecting)

        // Using CaseAssociatedValueDetection macro - namespaced access
        if let errorInfo = state.error {
            print("Error: \(errorInfo.localizedDescription)")
        }

        if let sentInfo = state.sent {
            print("Sent at \(sentInfo.date) with count \(sentInfo.count)")
        }

        if let eligibleInfo = state.eligible {
            print("Progress: \(eligibleInfo.stepsComplete)/\(eligibleInfo.stepsTotal)")
        }
    }

    // MARK: - Enum-in-Enum Example

    func nestedEnumUsage() {
        let state = MyState.status(utsStatus: .unlocking(stepsComplete: 3, stepsTotal: 5))

        // Access the nested enum
        if let statusInfo = state.status {
            let utsStatus = statusInfo.utsStatus

            // Now access the nested enum's associated values
            if let unlockingInfo = utsStatus.unlocking {
                print("Unlocking: \(unlockingInfo.stepsComplete)/\(unlockingInfo.stepsTotal)")
            }

            // Or check the nested enum's case
            if utsStatus.isLocked {
                print("Status is locked")
            }
        }
    }

    // MARK: - Optional Chaining Examples

    func optionalChainingExamples() {
        let errorState = MyState.error(localizedDescription: "Network unavailable")

        // Combine both macros with optional chaining
        if errorState.isError {
            print(errorState.error?.localizedDescription ?? "Unknown error")
        }

        // Nil coalescing with default values
        let message = state.messaging?.message ?? "No message"
        print(message)

        // Optional chaining with nested properties
        let completedSteps = state.eligible?.stepsComplete ?? 0
        print("Completed: \(completedSteps)")
    }

    // MARK: - Switch Statement Alternative

    func switchAlternative() {
        // Instead of traditional switch, use the generated properties
        if state.isConnecting {
            print("Connecting...")
        } else if let message = state.messaging {
            print("Message: \(message.message)")
        } else if let error = state.error {
            print("Error: \(error.localizedDescription)")
        } else if let sent = state.sent {
            print("Sent \(sent.count) items at \(sent.date)")
        }
    }

    // MARK: - Practical Examples

    func practicalExamples() {
        // Example 1: Form validation
        let states: [MyState] = [
            .error(localizedDescription: "Invalid email"),
            .sent(date: Date(), count: 1),
            .connecting,
        ]

        let errorMessages = states.compactMap(\.error).map(\.localizedDescription)
        print("Errors: \(errorMessages)")

        // Example 2: Progress tracking
        let progressState = MyState.eligible(stepsComplete: 7, stepsTotal: 10)
        if let progress = progressState.eligible {
            let percentage = Double(progress.stepsComplete) / Double(progress.stepsTotal) * 100
            print("Progress: \(percentage)%")
        }

        // Example 3: Counting sent items
        let sentStates = states.filter(\.isSent)
        let totalSent = sentStates.compactMap(\.sent).reduce(0) { $0 + $1.count }
        print("Total sent: \(totalSent)")
    }

    // MARK: - Mapping and Transforming

    func mappingExamples() {
        let states: [MyState] = [
            .sent(date: Date(), count: 5),
            .sent(date: Date().addingTimeInterval(-3600), count: 10),
            .error(localizedDescription: "Failed"),
        ]

        // Map to extract specific associated values
        let sentCounts = states.compactMap { state in
            state.sent?.count
        }
        print("Sent counts: \(sentCounts)")

        // Filter by case and transform
        let recentSends = states
            .compactMap(\.sent)
            .filter { $0.date.timeIntervalSinceNow > -7200 }
            .map(\.count)
        print("Recent sends: \(recentSends)")
    }

    // MARK: - Guard Statement Usage

    func guardStatementExample(_ state: MyState) {
        // Clean guard statements with early returns
        guard let error = state.error else {
            print("Not an error state")
            return
        }

        print("Handling error: \(error.localizedDescription)")
        // Handle error...
    }

    // MARK: - Computed Property Example

    var stateDescription: String {
        if state.isConnecting {
            return "Connecting..."
        } else if let msg = state.messaging {
            return "Message: \(msg.message)"
        } else if let err = state.error {
            return "Error: \(err.localizedDescription)"
        } else if let sent = state.sent {
            return "Sent \(sent.count) at \(sent.date)"
        } else if let eligible = state.eligible {
            return "Eligible: \(eligible.stepsComplete)/\(eligible.stepsTotal)"
        } else if let status = state.status {
            if status.utsStatus.isLocked {
                return "Status: Locked"
            } else if let unlocking = status.utsStatus.unlocking {
                return "Status: Unlocking \(unlocking.stepsComplete)/\(unlocking.stepsTotal)"
            } else {
                return "Status: Unlocked"
            }
        }
        return "Unknown"
    }
}
