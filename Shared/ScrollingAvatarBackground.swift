//
//  ScrollingAvatarBackground.swift
//  Testing
//
//  Created by Ricky on 3/12/25.
//

import SwiftUI

class ScrollingAvatarViewModel: ObservableObject {
    let velocity: Double
    let spacing: CGFloat
    var previousTick: Date = .now
    var contentWidth: CGFloat = 0

    init(velocity: Double, spacing: CGFloat) {
        self.velocity = velocity
        self.spacing = spacing
    }

    func duplicateInstances(for containerWidth: CGFloat) -> Int {
        return max(1, Int(containerWidth / (contentWidth + spacing)))
    }

    func offset(for date: Date) -> CGFloat {
        let elapsed = date.timeIntervalSince(previousTick)
        return -CGFloat(elapsed) * velocity
    }
}

struct ScrollingAvatarBackground: View {
    @State private var containerWidth: CGFloat = 0
    @State private var viewModel = ScrollingAvatarViewModel(velocity: 20, spacing: 10)

    private let avatarCount = 50

    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { context in
                VStack(spacing: viewModel.spacing) {
                    ForEach(0 ..< viewModel.duplicateInstances(for: containerWidth), id: \.self) { index in
                        avatarRow
                            .offset(x: index.isMultiple(of: 2) ? 0 : -100)
                    }
                }
                .offset(x: viewModel.offset(for: context.date))
                .frame(width: geo.size.width, alignment: .leading)
            }
            .onFrameChange(in: .local) { frame in
                containerWidth = frame.width
            }
        }
        .onAppear {
            viewModel.previousTick = .now
        }
    }

    private var avatarRow: some View {
        let range = (1...avatarCount).shuffled()
        
        return HStack(spacing: viewModel.spacing) {
            ForEach(range, id: \.self) { index in
                Image("avatar-\(index)")
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            }
        }
    }
}

#Preview {
    ScrollingAvatarBackground()
}
