//
//  EpisodeCardView.swift
//  TestDrive
//

import SwiftUI
import SFSymbols

/// A scrollable card displaying episode details for comparison.
struct EpisodeCardView: View {
    let episode: Episode
    let onSelect: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    episodeImage

                    VStack(alignment: .leading, spacing: 8) {
                        Text(episode.episodeCode)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.2))
                            .clipShape(Capsule())

                        Text(episode.name)
                            .font(.headline)

                        if !episode.overviewText.isEmpty {
                            Text(episode.overviewText)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                }
            }

            Button {
                onSelect()
            } label: {
                Text("Select")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
            }
        }
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }

    // MARK: - Private Views

    private var episodeImage: some View {
        AsyncImage(url: episode.stillURL) { phase in
            switch phase {
            case .empty:
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .aspectRatio(16/9, contentMode: .fit)
                    .overlay {
                        ProgressView()
                    }
            case .success(let image):
                image
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .aspectRatio(16/9, contentMode: .fit)
                    .clipped()
            case .failure:
                Rectangle()
                    .fill(Color.secondary.opacity(0.2))
                    .aspectRatio(16/9, contentMode: .fit)
                    .overlay {
                        VStack(spacing: 8) {
                            Image(symbol: .photoTv)
                                .font(.largeTitle)
                            Text(episode.episodeCode)
                                .font(.caption)
                        }
                        .foregroundStyle(.secondary)
                    }
            @unknown default:
                EmptyView()
            }
        }
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 16,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 16
            )
        )
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(colorScheme == .dark ? Color(.systemGray6) : Color.white)
    }
}

#Preview {
    HStack(spacing: 16) {
        EpisodeCardView(
            episode: Episode(
                id: 1,
                name: "Children of the Gods",
                overview: "Colonel Jack O'Neill is brought out of retirement to lead a new expedition through the Stargate.",
                episodeNumber: 1,
                seasonNumber: 1,
                stillPath: nil,
                airDate: "1997-07-27"
            )
        ) {
            print("Selected")
        }

        EpisodeCardView(
            episode: Episode(
                id: 2,
                name: "The Enemy Within",
                overview: "The team discovers that one of their own has been compromised.",
                episodeNumber: 2,
                seasonNumber: 1,
                stillPath: nil,
                airDate: "1997-08-01"
            )
        ) {
            print("Selected")
        }
    }
    .padding()
    .background(Color(.systemBackground))
}
