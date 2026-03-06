import SwiftUI
import PhotosUI

/// Main view for the word search solver feature.
struct WordSearchView: View {
    @State private var viewModel = WordSearchViewModel()

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    photoPicker

                    if viewModel.isProcessing {
                        ProgressView("Analyzing image...")
                    }

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.callout)
                    }

                    if let image = viewModel.selectedImage {
                        imageSection(image)
                    }

                    if !viewModel.grid.isEmpty {
                        gridSection
                    }

                    if !viewModel.words.isEmpty {
                        wordListSection
                    }
                }
                .padding()
            }
            .navigationTitle("Word Search Solver")
        }
    }

    // MARK: - Private Views

    private var photoPicker: some View {
        PhotosPicker(
            selection: $viewModel.selectedItem,
            matching: .images
        ) {
            Label("Select Word Search Photo", systemImage: "photo")
                .frame(maxWidth: .infinity)
                .padding()
                .background(.blue.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .onChange(of: viewModel.selectedItem) {
            Task {
                await viewModel.loadImage()
            }
        }
    }

    private func imageSection(_ image: UIImage) -> some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(radius: 4)
    }

    private var gridSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Detected Grid")
                .font(.headline)

            let grid = viewModel.grid
            let cellSize: CGFloat = 22

            LazyVGrid(
                columns: Array(
                    repeating: GridItem(.fixed(cellSize), spacing: 2),
                    count: grid.first?.count ?? 0
                ),
                spacing: 2
            ) {
                ForEach(0..<grid.count, id: \.self) { row in
                    ForEach(0..<grid[row].count, id: \.self) { col in
                        let position = GridPosition(row: row, col: col)
                        Text(String(grid[row][col]))
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .frame(width: cellSize, height: cellSize)
                            .background(
                                viewModel.color(for: position)?.opacity(0.35) ?? .clear
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 3))
                    }
                }
            }
            .padding(8)
            .background(.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private var wordListSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Words")
                    .font(.headline)

                Spacer()

                Text("\(viewModel.foundWords.count)/\(viewModel.words.count) found")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(
                columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ],
                spacing: 8
            ) {
                ForEach(viewModel.words, id: \.self) { word in
                    let isFound = viewModel.foundWordStrings.contains(word)

                    Text(word)
                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 6)
                        .background(
                            isFound
                                ? viewModel.color(for: word).opacity(0.25)
                                : Color.gray.opacity(0.1)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(
                                    isFound ? viewModel.color(for: word) : .clear,
                                    lineWidth: 2
                                )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .strikethrough(isFound, color: viewModel.color(for: word))
                }
            }
        }
    }
}

#Preview {
    WordSearchView()
}
