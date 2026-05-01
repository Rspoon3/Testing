//
//  RankedPhotosListView.swift
//  TestDrive
//

import SwiftUI

/// Displays a ranked list of photos after comparison.
struct RankedPhotosListView: View {
    private let photos: [PhotoItem]
    private let useScrollView: Bool
    
    // MARK: - Initializer
    
    init(photos: [PhotoItem], useScrollView: Bool = true) {
        self.photos = photos
        self.useScrollView = useScrollView
    }

    // MARK: - Body

    var body: some View {
        if useScrollView {
            ScrollView {
                content
            }
        } else {
            content
        }
    }
    
    private var content: some View {
        VStack(alignment: .leading, spacing: 20) {
            ForEach(Array(photos.enumerated()), id: \.element.id) { index, photo in
                HStack(spacing: 15) {
                    // Rank indicator
                    ZStack {
                        Circle()
                            .fill(rankColor(for: index))
                            .frame(width: 50, height: 50)

                        Text("#\(index + 1)")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }

                    // Photo thumbnail
                    Image(uiImage: photo.image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 100, height: 100)
                        .clipped()
                        .cornerRadius(10)

                    // Rank label
                    VStack(alignment: .leading) {
                        Text(rankTitle(for: index))
                            .font(.headline)

                        Text("Rank \(index + 1) of \(photos.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.secondarySystemBackground))
                )
                .padding(.horizontal)
            }
        }
        .padding(.vertical)
    }

    // MARK: - Private Helpers

    private func rankColor(for index: Int) -> Color {
        switch index {
        case 0: return .yellow
        case 1: return .gray
        case 2: return .orange
        default: return .blue
        }
    }

    private func rankTitle(for index: Int) -> String {
        switch index {
        case 0: return "🥇 Best Photo"
        case 1: return "🥈 Second Place"
        case 2: return "🥉 Third Place"
        default: return "Rank \(index + 1)"
        }
    }
}
