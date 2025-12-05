import SwiftUI
import SFSymbols

/// A single animated word in the word cloud.
struct FloatingWordView: View {
    let word: OnboardingWord
    let onTap: () -> Void

    @State private var isAnimating = false

    private var floatOffset: CGSize {
        CGSize(
            width: isAnimating ? 8 : -8,
            height: isAnimating ? 12 : -12
        )
    }

    // MARK: - Body

    var body: some View {
        Button {
            onTap()
        } label: {
            HStack(spacing: 8) {
                Image(symbol: word.attitude.symbol)
                Text(word.attitude.displayName)
                    .font(.headline)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(word.isSelected ? Color.accentColor : Color.secondary.opacity(0.15))
            )
            .foregroundStyle(word.isSelected ? .white : .primary)
            .scaleEffect(word.isSelected ? 1.1 : 1.0)
        }
        .buttonStyle(.plain)
        .offset(floatOffset)
        .animation(
            Animation
                .easeInOut(duration: 2.0 + word.animationPhase)
                .repeatForever(autoreverses: true)
                .delay(word.animationPhase),
            value: isAnimating
        )
        .animation(.spring(response: 0.3), value: word.isSelected)
        .onAppear {
            isAnimating = true
        }
    }
}

#Preview {
    FloatingWordView(
        word: OnboardingWord(
            attitude: .encouraging,
            initialOffset: .zero,
            animationPhase: 0
        ),
        onTap: {}
    )
}
