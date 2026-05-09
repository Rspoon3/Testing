import SwiftUI

struct InviteFriendsContentView: View {
    @StateObject private var viewModel = InviteFriendsViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                topView
                backgroundShape
                referralCodeWithButtonView
            }
            .padding(.bottom)
            .multilineTextAlignment(.center)
        }
        .background(Color(.systemBackground))
        .sheet(isPresented: $viewModel.isShowingCustomCodeInput) {
            CustomReferralCodeInputView(viewModel: viewModel)
        }
    }

    // MARK: - Private

    private var topView: some View {
        VStack(spacing: 16) {
            headerViews
            buttonViews
            Text("Got questions about how it works? Tap here for FAQs.")
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.85))
                .padding(.horizontal)
                .padding(.bottom, 8)
        }
        .frame(maxWidth: .infinity)
        .padding([.bottom, .horizontal])
        .background(Color.purple)
    }

    private var backgroundShape: some View {
        ReferralBackgroundShape()
            .fill(Color.purple)
            .frame(height: 20)
            .padding(.bottom, 24)
    }

    private var referralCodeWithButtonView: some View {
        VStack(spacing: 16) {
            Image(systemName: "qrcode")
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .foregroundStyle(.primary)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )

            Button("Enter a Referral Code") {}
                .buttonStyle(.bordered)
                .controlSize(.large)
                .padding(.top, 8)
        }
        .padding()
    }

    private var headerViews: some View {
        VStack(spacing: 8) {
            Text("Refer a Friend")
                .font(.largeTitle.bold())
                .foregroundStyle(.white)

            Text("Earn 2,000 points for every friend who joins!")
                .font(.headline)
                .foregroundStyle(.white)

            HStack(spacing: 8) {
                Text(viewModel.referralCode)
                    .font(.title2.bold().monospaced())
                    .foregroundStyle(.white)

                Button {
                    viewModel.beginEditing()
                } label: {
                    Image(systemName: "pencil.line")
                        .font(.title3)
                        .foregroundStyle(.white)
                }
                .accessibilityLabel("Edit referral code")
            }
            .padding(.top, 4)
        }
        .padding(.top)
    }

    private var buttonViews: some View {
        HStack(spacing: 12) {
            ReferralChip(title: "Text", systemImage: "message.fill") {}
            ReferralChip(title: "Email", systemImage: "envelope.fill") {}
            ReferralChip(title: "Share", systemImage: "square.and.arrow.up") {}
        }
        .padding(.bottom)
    }
}

// MARK: - Supporting Views

private struct ReferralChip: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                Text(title)
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(Color.purple)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Capsule().fill(.white))
        }
    }
}

private struct ReferralBackgroundShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY),
            control: CGPoint(x: rect.midX, y: rect.maxY * 2)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    InviteFriendsContentView()
}
