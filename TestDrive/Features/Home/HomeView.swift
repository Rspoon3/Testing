//
//  HomeView.swift
//  TestDrive
//

import SwiftUI
import SFSymbols

/// The main entry point view for the app.
struct HomeView: View {
    @State private var viewModel = HomeViewModel()
    @State private var showSearch = false
    @State private var selectedSession: RankingSession?
    @State private var completedSession: RankingSession?

    // MARK: - Body

    var body: some View {
        NavigationStack {
            List {
                if !viewModel.inProgressSessions.isEmpty {
                    inProgressSection
                }

                if !viewModel.completedSessions.isEmpty {
                    completedSection
                }

                if viewModel.sessions.isEmpty && !viewModel.isLoading {
                    emptyStateSection
                }
            }
            .navigationTitle("Episode Ranker")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showSearch = true
                    } label: {
                        Image(symbol: .plus)
                    }
                }
            }
            .refreshable {
                await viewModel.loadSessions()
            }
            .task {
                await viewModel.loadSessions()
            }
            .sheet(isPresented: $showSearch) {
                NavigationStack {
                    SearchView()
                }
            }
            .fullScreenCover(item: $selectedSession) { session in
                EpisodeComparisonView(session: session) {
                    selectedSession = nil
                    Task {
                        await viewModel.loadSessions()
                    }
                }
            }
            .sheet(item: $completedSession) { session in
                if let winner = session.winnerEpisode {
                    WinnerView(episode: winner, showName: session.showName)
                }
            }
        }
    }

    // MARK: - Private Views

    private var inProgressSection: some View {
        Section("In Progress") {
            ForEach(viewModel.inProgressSessions) { session in
                SessionRow(session: session)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedSession = session
                    }
            }
            .onDelete { offsets in
                Task {
                    await viewModel.deleteSessions(at: offsets)
                }
            }
        }
    }

    private var completedSection: some View {
        Section("Completed") {
            ForEach(viewModel.completedSessions) { session in
                SessionRow(session: session)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        completedSession = session
                    }
            }
            .onDelete { offsets in
                let completedOffsets = IndexSet(offsets.map { index in
                    viewModel.sessions.firstIndex(of: viewModel.completedSessions[index]) ?? index
                })
                Task {
                    await viewModel.deleteSessions(at: completedOffsets)
                }
            }
        }
    }

    private var emptyStateSection: some View {
        Section {
            VStack(spacing: 16) {
                Image(symbol: .tvAndMediabox)
                    .font(.system(size: 60))
                    .foregroundStyle(.secondary)

                Text("No Rankings Yet")
                    .font(.headline)

                Text("Tap + to search for a TV show and start ranking episodes.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)

                Button {
                    showSearch = true
                } label: {
                    Text("Search TV Shows")
                }
                .buttonStyle(.borderedProminent)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        }
    }
}

/// Row displaying a ranking session.
private struct SessionRow: View {
    let session: RankingSession

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: session.showPosterURL) { phase in
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
            .frame(width: 50, height: 75)
            .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 4) {
                Text(session.showName)
                    .font(.headline)
                    .lineLimit(1)

                if session.isComplete {
                    if let winner = session.winnerEpisode {
                        Text("Winner: \(winner.episodeCode)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ProgressView(value: session.progress)
                        .progressViewStyle(.linear)

                    Text("\(session.progress.formatted(.percent.precision(.fractionLength(0)))) complete")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if !session.isComplete {
                Image(symbol: .chevronRight)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    HomeView()
}
