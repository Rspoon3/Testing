import SwiftUI

/// Displays an animated word cloud for multi-attitude selection.
struct WordCloudView: View {
    @Binding var selectedAttitudes: Set<Attitude>
    @State private var words: [OnboardingWord] = []

    private let columns = [
        GridItem(.adaptive(minimum: 140, maximum: 200), spacing: 16)
    ]

    // MARK: - Body

    var body: some View {
        LazyVGrid(columns: columns, spacing: 24) {
            ForEach(words) { word in
                FloatingWordView(word: word) {
                    toggleWord(word)
                }
            }
        }
        .padding()
        .onAppear {
            initializeWords()
        }
    }

    // MARK: - Private Helpers

    private func initializeWords() {
        words = Attitude.allCases.enumerated().map { index, attitude in
            OnboardingWord(
                attitude: attitude,
                isSelected: selectedAttitudes.contains(attitude),
                initialOffset: CGSize(
                    width: CGFloat.random(in: -15...15),
                    height: CGFloat.random(in: -15...15)
                ),
                animationPhase: Double(index) * 0.25
            )
        }
    }

    private func toggleWord(_ word: OnboardingWord) {
        if let index = words.firstIndex(where: { $0.id == word.id }) {
            words[index].isSelected.toggle()

            if words[index].isSelected {
                selectedAttitudes.insert(word.attitude)
            } else {
                selectedAttitudes.remove(word.attitude)
            }
        }
    }
}

#Preview {
    @Previewable @State var selected: Set<Attitude> = []
    WordCloudView(selectedAttitudes: $selected)
}
