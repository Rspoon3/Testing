//
//  StarRatingView.swift
//  AppRatingFeature
//
//  Created on 9/25/25.
//

import SwiftUI

/// Interactive star rating view
public struct StarRatingView: View {
    @Binding var rating: Int
    let maxRating: Int
    let onRatingChanged: ((Int) -> Void)?

    public init(
        rating: Binding<Int>,
        maxRating: Int = 5,
        onRatingChanged: ((Int) -> Void)? = nil
    ) {
        self._rating = rating
        self.maxRating = maxRating
        self.onRatingChanged = onRatingChanged
    }

    public var body: some View {
        HStack(spacing: 8) {
            ForEach(1...maxRating, id: \.self) { star in
                Button {
                    withAnimation {
                        rating = star
                        onRatingChanged?(star)

                        // Haptic feedback
                        let impact = UIImpactFeedbackGenerator(style: .light)
                        impact.impactOccurred()
                    }
                } label: {
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .resizable()
                        .scaledToFit()
                        .foregroundColor(.yellow)
                }
                .buttonStyle(.plain)
                .animation(.spring, value: rating)
            }
        }
    }
}

#Preview {
    StarRatingView(rating: .constant(4))
}
