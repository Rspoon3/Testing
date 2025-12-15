//
//  SearchView.swift
//  TestDrive
//

import SwiftUI
import SFSymbols

/// View for searching TV shows.
struct SearchView: View {
    @State private var viewModel = SearchViewModel()
    @State private var selectedShow: TVShow?
    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        List {
            if viewModel.searchResults.isEmpty && !viewModel.isSearching {
                if viewModel.searchText.isEmpty {
                    searchPromptSection
                } else if let error = viewModel.errorMessage {
                    errorSection(error)
                } else {
                    noResultsSection
                }
            } else {
                searchResultsSection
            }
        }
        .listStyle(.plain)
        .navigationTitle("Search TV Shows")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search for a TV show..."
        )
        .onChange(of: viewModel.searchText) {
            viewModel.search()
        }
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") {
                    dismiss()
                }
            }
        }
        .navigationDestination(item: $selectedShow) { show in
            ShowDetailView(show: show)
        }
    }

    // MARK: - Private Views

    private var searchPromptSection: some View {
        Section {
            VStack(spacing: 16) {
                Image(symbol: .magnifyingglass)
                    .font(.system(size: 50))
                    .foregroundStyle(.secondary)

                Text("Search for a TV Show")
                    .font(.headline)

                Text("Find your favorite show to rank its episodes.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
        }
    }

    private func errorSection(_ error: String) -> some View {
        Section {
            VStack(spacing: 12) {
                Image(symbol: .exclamationmarkTriangle)
                    .font(.system(size: 40))
                    .foregroundStyle(.red)

                Text("Search Failed")
                    .font(.headline)

                Text(error)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        }
    }

    private var noResultsSection: some View {
        Section {
            VStack(spacing: 12) {
                Image(symbol: .tvSlash)
                    .font(.system(size: 40))
                    .foregroundStyle(.secondary)

                Text("No Results")
                    .font(.headline)

                Text("Try a different search term.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        }
    }

    private var searchResultsSection: some View {
        Section {
            ForEach(viewModel.searchResults) { show in
                ShowRow(show: show)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedShow = show
                    }
            }
        }
    }
}

/// Row displaying a TV show search result.
private struct ShowRow: View {
    let show: TVShow

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: show.posterURL) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))
                        .overlay {
                            ProgressView()
                        }
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFill()
                case .failure:
                    Rectangle()
                        .fill(Color.secondary.opacity(0.2))
                        .overlay {
                            Image(symbol: .photoTv)
                                .foregroundStyle(.secondary)
                        }
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 60, height: 90)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(show.name)
                    .font(.headline)
                    .lineLimit(2)

                if let year = show.yearString {
                    Text(year)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if !show.overviewText.isEmpty {
                    Text(show.overviewText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            Spacer()

            Image(symbol: .chevronRight)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NavigationStack {
        SearchView()
    }
}
