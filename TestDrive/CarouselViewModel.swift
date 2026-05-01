//
//  CarouselViewModel.swift
//  Testing
//
//  Created by Richard Witherspoon on 12/6/23.
//

import SwiftUI

@MainActor
final class CarouselViewModel: ObservableObject {
    @Published var id: Int? // = 250
    let maxValue = 500
    let scale: (max: CGFloat, min: CGFloat) = (1, 0.8)
    let spacing: CGFloat = 12
    
    nonisolated func yScale(using proxy: GeometryProxy) -> Double {
        let itemMidX = proxy.frame(in: .scrollView).midX
        
        guard let scrollViewWidth = proxy.bounds(of: .scrollView)?.width else {
            return 0
        }
        
        let scrollViewMidX = scrollViewWidth / 2
        let distanceFromCenter = abs(scrollViewMidX - itemMidX)
        let itemWidth = proxy.size.width
        let percentageToMidX = 1 - (distanceFromCenter / (itemWidth - spacing))
        let calculatedScale = ((scale.max - scale.min) * percentageToMidX) + scale.min
        return max(scale.min, calculatedScale)
    }
}
