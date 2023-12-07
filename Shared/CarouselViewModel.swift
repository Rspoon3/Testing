//
//  CarouselViewModel.swift
//  Testing
//
//  Created by Richard Witherspoon on 12/6/23.
//

import SwiftUI
import Clocks

@MainActor
final class CarouselViewModel: ObservableObject {
    @Published var id: Int? //= 500
    let maxValue = 50_000
    let scale: (max: CGFloat, min: CGFloat) = (1, 0.8)
    let safeAreaPadding: CGFloat = 16
    let clock: any Clock<Duration>
    var timerTask: Task<Void, Error>?

    // MARK: - Initializer
    
    init(clock: any Clock<Duration> = ContinuousClock()) {
        self.clock = clock
        self.timerTask = Task {
//            for await _ in self.clock.timer(interval: .seconds(3)) {
//                withAnimation {
//                    id = (id ?? 0) + 1
//                }
//            }
        }
    }
    
    // MARK: - Private Helpers
    
    @objc private func gestureRecognizerUpdate(panGesture: UIPanGestureRecognizer) {
        guard panGesture.state == .began else { return }
        self.timerTask?.cancel()
        self.timerTask = nil
    }
    
    // MARK: - Public Helpers
    
    func set(_ scrollView: UIScrollView) {
        scrollView.panGestureRecognizer.addTarget(self, action: #selector(gestureRecognizerUpdate))
    }
    
    nonisolated func yScale(using proxy: GeometryProxy) -> Double {
        let itemMidX = proxy.frame(in: .scrollView).midX
        
        guard let scrollViewWidth = proxy.bounds(of: .scrollView)?.width else {
            return 0
        }
        
        let scrollViewMidX = scrollViewWidth / 2
        let distanceFromCenter = abs(scrollViewMidX - itemMidX)
        let itemWidth = proxy.size.width
        let percentageToMidX = 1 - (distanceFromCenter / (itemWidth - safeAreaPadding))
        let calculatedScale = ((scale.max - scale.min) * percentageToMidX) + scale.min
        return max(scale.min, calculatedScale)
    }
}
