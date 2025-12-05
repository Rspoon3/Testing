import SwiftUI
import SFSymbols

/// A reusable grid for selecting multiple attitudes.
struct AttitudePickerView: View {
    @Binding var selectedAttitudes: Set<Attitude>

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    // MARK: - Body

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(Attitude.allCases) { attitude in
                AttitudeButton(
                    attitude: attitude,
                    isSelected: selectedAttitudes.contains(attitude)
                ) {
                    toggleAttitude(attitude)
                }
            }
        }
    }

    // MARK: - Private Helpers

    private func toggleAttitude(_ attitude: Attitude) {
        if selectedAttitudes.contains(attitude) {
            if selectedAttitudes.count > 1 {
                selectedAttitudes.remove(attitude)
            }
        } else {
            selectedAttitudes.insert(attitude)
        }
    }
}

// MARK: - AttitudeButton

private struct AttitudeButton: View {
    let attitude: Attitude
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(symbol: attitude.symbol)
                    .font(.title)

                Text(attitude.displayName)
                    .font(.subheadline.weight(.medium))

                Text(attitude.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? .blue : .primary)
    }
}

#Preview {
    @Previewable @State var selected: Set<Attitude> = [.encouraging]
    AttitudePickerView(selectedAttitudes: $selected)
        .padding()
}
