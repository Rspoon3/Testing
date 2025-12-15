//
//  ShowDetailView.swift
//  TestDrive
//

import SwiftUI
import SFSymbols

/// View displaying TV show details and starting the ranking.
struct ShowDetailView: View {
    @State private var viewModel: ShowDetailViewModel
    @State private var showComparison = false
    @State private var createdSession: RankingSession?
    @Environment(\.dismiss) private var dismiss

    // MARK: - Initializer

    init(show: TVShow) {
        _viewModel = State(wrappedValue: ShowDetailViewModel(show: show))
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                headerSection

                if viewModel.isLoading {
                    loadingSection
                } else if let error = viewModel.errorMessage {
                    errorSection(error)
                } else if !viewModel.episodes.isEmpty {
                    episodeInfoSection
                    startRankingButton
                }
            }
            .padding()
        }
        .navigationTitle(viewModel.show.name)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.fetchEpisodes()
        }
        .fullScreenCover(item: $createdSession) { session in
            EpisodeComparisonView(session: session) {
                createdSession = nil
                dismiss()
            }
        }
    }

    // MARK: - Private Views

    private var headerSection: some View {
        HStack(alignment: .top, spacing: 16) {
            AsyncImage(url: viewModel.show.posterURL) { phase in
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
                                .font(.largeTitle)
                                .foregroundStyle(.secondary)
                        }
                @unknown default:
                    EmptyView()
                }
            }
            .frame(width: 120, height: 180)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.show.name)
                    .font(.title2)
                    .fontWeight(.bold)

                if let year = viewModel.show.yearString {
                    Text(year)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let seasonCount = viewModel.show.numberOfSeasons {
                    Label("\(seasonCount) Seasons", symbol: .filmStack)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
    }

    private var loadingSection: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Loading episodes...")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 60)
    }

    private func errorSection(_ error: String) -> some View {
        VStack(spacing: 12) {
            Image(symbol: .exclamationmarkTriangle)
                .font(.system(size: 40))
                .foregroundStyle(.red)

            Text("Failed to Load Episodes")
                .font(.headline)

            Text(error)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Try Again") {
                Task {
                    await viewModel.fetchEpisodes()
                }
            }
            .buttonStyle(.bordered)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var episodeInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !viewModel.show.overviewText.isEmpty {
                Text(viewModel.show.overviewText)
                    .font(.body)
                    .foregroundStyle(.secondary)
            }

            Divider()

            HStack(spacing: 20) {
                VStack {
                    Text("\(viewModel.episodeCount)")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Episodes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Divider()
                    .frame(height: 40)

                VStack {
                    Text("\(viewModel.estimatedComparisons)")
                        .font(.title)
                        .fontWeight(.bold)
                    Text("Comparisons")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var startRankingButton: some View {
        Button {
            Task {
                do {
                    let session = try await viewModel.createSession()
                    createdSession = session
                } catch {
                    viewModel.errorMessage = error.localizedDescription
                }
            }
        } label: {
            Label("Start Ranking", symbol: .playFill)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
        }
        .buttonStyle(.borderedProminent)
        .disabled(viewModel.episodes.isEmpty)
    }
}

#Preview {
    NavigationStack {
        ShowDetailView(show: TVShow(
            id: 4629,
            name: "Stargate SG-1",
            overview: "The story of Stargate SG-1 begins about a year after the events of the feature film.",
            posterPath: "/bWgPKABdqzaJfGDWTEz4bCewb4h.jpg",
            backdropPath: nil,
            firstAirDate: "1997-07-27",
            numberOfSeasons: 10
        ))
    }
}
