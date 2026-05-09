import SwiftUI

struct CustomReferralCodeInputView: View {
    @ObservedObject var viewModel: InviteFriendsViewModel
    @FocusState private var isTextFieldFocused: Bool

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 32) {
            titleView
            rulesText

            VStack(spacing: 12) {
                inputSection
                validationText
            }

            Spacer()
        }
        .padding(.horizontal, 24)
        .padding(.top, 48)
        .background(Color(.systemBackground))
        .safeAreaInset(edge: .bottom) {
            bottomButtons
        }
        .onAppear {
            isTextFieldFocused = true
        }
        .alert(
            "Something went wrong",
            isPresented: $viewModel.didError
        ) {
            Button("OK") {
                isTextFieldFocused = true
            }
        } message: {
            Text("We couldn't update your referral code. Please try again.")
        }
    }

    // MARK: - Private Views

    private var titleView: some View {
        Text("Customize your referral code")
            .font(.title2.bold())
            .foregroundStyle(Color.purple)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }

    private var rulesText: some View {
        Text(viewModel.rules)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private var validationText: some View {
        if let validationMessage = viewModel.validationMessage {
            HStack(alignment: .center, spacing: 4) {
                Image(systemName: "exclamationmark.circle")
                    .resizable()
                    .frame(width: 12, height: 12)
                Text(validationMessage)
                    .font(.caption)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .foregroundStyle(.red)
            .frame(height: 20)
        }
    }

    private var inputSection: some View {
        TextField(
            "Enter referral code",
            text: Binding(
                get: { viewModel.customReferralCode },
                set: { viewModel.setCode($0) }
            )
        )
        .textFieldStyle(.roundedBorder)
        .font(.body.monospaced())
        .textInputAutocapitalization(.characters)
        .autocorrectionDisabled()
        .disabled(viewModel.isUpdating)
        .focused($isTextFieldFocused)
    }

    private var bottomButtons: some View {
        VStack(spacing: 16) {
            ZStack {
                Button {
                    Task {
                        if await viewModel.update() {
                            dismiss()
                        }
                    }
                } label: {
                    Text("Update")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!viewModel.canSubmit)
                .padding(.horizontal, 24)

                if viewModel.isUpdating {
                    ProgressView()
                        .frame(width: 24, height: 24)
                }
            }

            Button {
                dismiss()
            } label: {
                Text("Cancel")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(viewModel.isUpdating)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

#Preview {
    CustomReferralCodeInputView(viewModel: InviteFriendsViewModel())
}
