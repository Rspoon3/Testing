import SwiftUI
import SFSymbols

/// A row displaying a weight entry in the health list.
struct WeightRowView: View {
    let weightMessage: WeightMessage
    let formattedDate: String

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(symbol: .scalemass)
                    .font(.system(size: 20))
                    .foregroundStyle(.green)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Weight")
                    .font(.headline)

                HStack(spacing: 8) {
                    Text(weightMessage.formattedWeight)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("•")
                        .foregroundStyle(.secondary)

                    Text(formattedDate)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            Image(symbol: .bubbleLeftFill)
                .font(.caption)
                .foregroundStyle(.blue)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    List {
        WeightRowView(
            weightMessage: WeightMessage(
                weightEntryID: "123",
                weightInPounds: 175.5,
                message: "Nice progress!",
                attitudes: "encouraging",
                entryDate: Date()
            ),
            formattedDate: "Today at 8:30 AM"
        )
    }
}
