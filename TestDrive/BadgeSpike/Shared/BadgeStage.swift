//
//  BadgeStage.swift
//  TestDrive
//

import SwiftUI

/// The common chrome every tab sits in: a dark stage, a badge picker, and a note
/// on what the technique does and where it breaks.
///
/// Shared so the five approaches are judged on the same background, at the same
/// size, with the same badge — the differences on screen are then only the
/// rendering technique.
struct BadgeStage<Content: View>: View {
    private let notes: [String]
    private let selection: Binding<Badge>
    private let content: (Badge) -> Content

    // MARK: - Initializer

    /// Creates a stage.
    /// - Parameters:
    ///   - selection: The badge being shown.
    ///   - notes: Bullet points describing the technique's trade-offs.
    ///   - content: The badge renderer under test.
    init(
        selection: Binding<Badge>,
        notes: [String],
        @ViewBuilder content: @escaping (Badge) -> Content
    ) {
        self.selection = selection
        self.notes = notes
        self.content = content
    }

    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                stage
                picker
                noteList
            }
            .padding(.vertical, 24)
        }
        .background(.black)
        .scrollBounceBehavior(.basedOnSize)
    }

    // MARK: - Private Views

    /// The badge itself, on a subtle spotlit backdrop.
    private var stage: some View {
        content(selection.wrappedValue)
            .frame(width: 300, height: 300)
            .background {
                RadialGradient(
                    colors: [.white.opacity(0.12), .clear],
                    center: .center,
                    startRadius: 10,
                    endRadius: 190
                )
            }
    }

    /// Switches between the four sample finishes.
    private var picker: some View {
        HStack(spacing: 14) {
            ForEach(Badge.samples) { badge in
                Button {
                    selection.wrappedValue = badge
                } label: {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: badge.finish.faceColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 38, height: 38)
                        .overlay {
                            Circle()
                                .strokeBorder(
                                    .white.opacity(badge == selection.wrappedValue ? 0.95 : 0.15),
                                    lineWidth: 2
                                )
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(badge.title)
            }
        }
    }

    /// The trade-off notes.
    private var noteList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(selection.wrappedValue.title)
                .font(.headline)
                .foregroundStyle(.white)

            ForEach(notes, id: \.self) { note in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("•")
                    Text(note)
                }
                .font(.footnote)
                .foregroundStyle(.white.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
    }
}
