//
//  EpisodeComparisonView.swift
//  TestDrive
//

import SwiftUI
import SFSymbols

/// View for comparing two episodes side by side.
struct EpisodeComparisonView: View {
    @State private var viewModel: EpisodeComparisonViewModel
    @State private var showWinner = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let onDismiss: () -> Void

    private let cardSpacing: CGFloat = 16

    // MARK: - Initializer

    init(session: RankingSession, onDismiss: @escaping () -> Void) {
        _viewModel = State(wrappedValue: EpisodeComparisonViewModel(session: session))
        self.onDismiss = onDismiss
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                ProgressHeader(progress: viewModel.progress)
                    .padding(.horizontal)

                if let comparison = viewModel.currentComparison {
                    comparisonContent(comparison)
                } else {
                    loadingView
                }
            }
            .padding(.vertical)
            .navigationTitle("Which is Better?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        onDismiss()
                    } label: {
                        Image(symbol: .xmark)
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    if viewModel.canUndo {
                        Button {
                            withAnimation {
                                viewModel.undo()
                            }
                        } label: {
                            Image(symbol: .arrowUturnBackward)
                        }
                    }
                }
            }
            .sensoryFeedback(.increase, trigger: viewModel.progress)
            .onChange(of: viewModel.isComplete) { _, isComplete in
                if isComplete {
                    Task {
                        await viewModel.completeSession()
                        showWinner = true
                    }
                }
            }
            .fullScreenCover(isPresented: $showWinner) {
                if let winner = viewModel.winner {
                    WinnerView(episode: winner, showName: viewModel.session.showName) {
                        showWinner = false
                        onDismiss()
                    }
                }
            }
        }
    }

    // MARK: - Private Views

    private func comparisonContent(_ comparison: (left: Episode, right: Episode)) -> some View {
        GeometryReader { geometry in
            HStack(spacing: cardSpacing) {
                EpisodeCardView(episode: comparison.left) {
                    selectEpisode(isLeft: true)
                }
                .frame(width: cardWidth(for: geometry))

                EpisodeCardView(episode: comparison.right) {
                    selectEpisode(isLeft: false)
                }
                .frame(width: cardWidth(for: geometry))
            }
            .padding(.horizontal)
        }
    }

    private var loadingView: some View {
        VStack {
            Spacer()
            ProgressView()
            Spacer()
        }
    }

    // MARK: - Private Helpers

    private func cardWidth(for geometry: GeometryProxy) -> CGFloat {
        let totalSpacing = cardSpacing + 32 // Card spacing + horizontal padding
        return (geometry.size.width - totalSpacing) / 2
    }

    private func selectEpisode(isLeft: Bool) {
        withAnimation(reduceMotion ? .none : .spring(response: 0.3)) {
            viewModel.selectEpisode(isLeft: isLeft)
        }
    }
}

#Preview {
    let episodes = [
        Episode(id: 1, name: "Children of the Gods", overview: "Colonel Jack O'Neill is brought out of retirement.", episodeNumber: 1, seasonNumber: 1, stillPath: nil, airDate: nil),
        Episode(id: 2, name: "The Enemy Within", overview: "The team discovers a problem.", episodeNumber: 2, seasonNumber: 1, stillPath: nil, airDate: nil),
        Episode(id: 3, name: "Emancipation", overview: "Carter is kidnapped.", episodeNumber: 3, seasonNumber: 1, stillPath: nil, airDate: nil),
        Episode(id: 4, name: "The Broca Divide", overview: "The team visits a primitive world.", episodeNumber: 4, seasonNumber: 1, stillPath: nil, airDate: nil)
    ]

    let session = RankingSession(
        showId: 4629,
        showName: "Stargate SG-1",
        showPosterPath: nil,
        episodes: episodes
    )

    EpisodeComparisonView(session: session) {
        print("Dismissed")
    }
}
