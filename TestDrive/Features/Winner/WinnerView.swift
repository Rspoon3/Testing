//
//  WinnerView.swift
//  TestDrive
//

import SwiftUI
import SFSymbols

/// View displaying the winning episode.
struct WinnerView: View {
    let episode: Episode
    let showName: String
    var onDismiss: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    trophySection

                    episodeSection

                    if onDismiss != nil {
                        doneButton
                    }
                }
                .padding()
            }
            .navigationTitle("Winner!")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if onDismiss == nil {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }

    // MARK: - Private Views

    private var trophySection: some View {
        VStack(spacing: 16) {
            Image(symbol: .trophy)
                .font(.system(size: 80))
                .foregroundStyle(.yellow)
                .shadow(color: .yellow.opacity(0.5), radius: 20)

            Text("Your Favorite Episode")
                .font(.title2)
                .fontWeight(.bold)

            Text(showName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.top, 20)
    }

    private var episodeSection: some View {
        VStack(spacing: 16) {
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
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.2), radius: 10, y: 5)

            VStack(spacing: 8) {
                Text(episode.episodeCode)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.secondary.opacity(0.2))
                    .clipShape(Capsule())

                Text(episode.name)
                    .font(.title3)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                if !episode.overviewText.isEmpty {
                    Text(episode.overviewText)
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 4)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private var doneButton: some View {
        Button {
            onDismiss?()
        } label: {
            Text("Done")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
        }
        .buttonStyle(.borderedProminent)
    }
}

#Preview {
    WinnerView(
        episode: Episode(
            id: 1,
            name: "Window of Opportunity",
            overview: "O'Neill and Teal'c are caught in a time loop, repeating the same day over and over.",
            episodeNumber: 6,
            seasonNumber: 4,
            stillPath: nil,
            airDate: "2000-08-04"
        ),
        showName: "Stargate SG-1"
    )
}
