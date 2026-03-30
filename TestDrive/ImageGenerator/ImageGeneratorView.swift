import SwiftUI

/// Main view for generating and saving 16:9 background images.
struct ImageGeneratorView: View {
    @State private var viewModel = ImageGeneratorViewModel()

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                BackgroundCanvasView(style: viewModel.selectedStyle, seed: viewModel.seed)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(radius: 4)
                    .padding(.horizontal)

                stylePicker
                actionButtons

                Spacer()
            }
            .padding(.top)
            .navigationTitle("Background Generator")
            .alert("Saved!", isPresented: $viewModel.showSavedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Image saved to your photo library.")
            }
            .alert("Error", isPresented: .init(
                get: { viewModel.saveError != nil },
                set: { if !$0 { viewModel.saveError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.saveError ?? "")
            }
        }
    }

    // MARK: - Private Views

    private var stylePicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(BackgroundStyle.allCases) { style in
                    StyleChip(
                        title: style.title,
                        isSelected: viewModel.selectedStyle == style
                    ) {
                        viewModel.selectedStyle = style
                    }
                }
            }
            .padding(.horizontal)
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 16) {
            Button {
                viewModel.randomize()
            } label: {
                Label("Shuffle", systemImage: "shuffle")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.secondary)

            Button {
                viewModel.saveImage()
            } label: {
                Label("Save", systemImage: "square.and.arrow.down")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isSaving)
        }
        .padding(.horizontal)
    }
}

/// A selectable chip for picking a background style.
private struct StyleChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .foregroundStyle(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
    }
}

#Preview {
    ImageGeneratorView()
}
