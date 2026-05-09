import Combine
import SwiftUI

@MainActor
final class InviteFriendsViewModel: ObservableObject {
    @Published var referralCode: String = "RICKY123"
    @Published var customReferralCode: String = ""
    @Published var isShowingCustomCodeInput: Bool = false
    @Published var isUpdating: Bool = false
    @Published var didError: Bool = false

    let characterLimit = 12
    let rules = "Codes must be 4–12 characters. Letters and numbers only."

    var validationMessage: String? {
        guard !customReferralCode.isEmpty else { return nil }
        if customReferralCode.count < 4 {
            return "Code is too short."
        }
        if customReferralCode.contains(where: { !$0.isLetter && !$0.isNumber }) {
            return "Only letters and numbers are allowed."
        }
        return nil
    }

    var canSubmit: Bool {
        !isUpdating
            && validationMessage == nil
            && customReferralCode.count >= 4
            && customReferralCode != referralCode
    }

    func beginEditing() {
        customReferralCode = ""
        isShowingCustomCodeInput = true
    }

    func setCode(_ value: String) {
        customReferralCode = String(value.prefix(characterLimit)).uppercased()
    }

    func update() async -> Bool {
        isUpdating = true
        defer { isUpdating = false }

        try? await Task.sleep(for: .seconds(1))

        // Simulate a random failure for demo purposes.
        if Bool.random() {
            didError = true
            return false
        }

        referralCode = customReferralCode
        return true
    }
}
