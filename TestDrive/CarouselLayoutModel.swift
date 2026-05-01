//
//  CarouselLayoutModel.swift
//  FetchRewards
//
//  Created by Richard Witherspoon on 1/27/23.
//  Copyright © 2023 Fetch Rewards, LLC. All rights reserved.
//

import SwiftUI
import Combine

final class CarouselLayoutModel {
    let spacing: CGFloat = 12
    let cellSize: CGSize
    let midScale: CGFloat
    let interGroupSpacing: CGFloat
    var collectionViewWidth: CGFloat
    var startOfScrollIndex = IndexPath(item: 0, section: 0)
    private let maxScale: CGFloat = 1
    private let minScale: CGFloat = 0.8
    @Binding var indexPath: IndexPath
//    weak var delegate: CarouselLayoutModelDelegate?
    
    struct Calculation {
        let percentageToMidX: CGFloat
        let scale: CGFloat
    }
    
    // MARK: - Initalizer
    
    init(collectionViewWidth: CGFloat, indexPath: Binding<IndexPath>) {
        _indexPath = indexPath
        self.collectionViewWidth = collectionViewWidth
        
        let cellWidth = collectionViewWidth - spacing * 4
        let cellHeight = cellWidth / 2
        
        cellSize = .init(width: cellWidth, height: cellHeight)
        midScale = maxScale - ((maxScale - minScale) / 2)
        interGroupSpacing = -(cellWidth - (cellWidth * minScale)) / 2 + spacing
    }
    
    // MARK: - Public Helpers
    
    func getSectionInset(collectionViewFrame: CGRect, adjustedContentInset: UIEdgeInsets) -> UIEdgeInsets {
        let bottomInsets = (collectionViewFrame.height - adjustedContentInset.top - adjustedContentInset.bottom - cellSize.height)
        let horizontalInsets = (collectionViewFrame.width - adjustedContentInset.right - adjustedContentInset.left - cellSize.width) / 2
        
        return UIEdgeInsets(top: 0, left: horizontalInsets, bottom: bottomInsets, right: horizontalInsets)
    }
    
    func performScaleCalulations(midX: CGFloat, xOffset: CGFloat) -> Calculation {
        let distanceFromCenter = abs((midX - xOffset) - collectionViewWidth / 2.0)
        let width = cellSize.width + interGroupSpacing
        
        var percentageToMidX = 1 - (distanceFromCenter / width)
        percentageToMidX = min(1, percentageToMidX)
        percentageToMidX = max(0, percentageToMidX)
        
        let scale = minScale + (maxScale - minScale) * percentageToMidX
        
        return Calculation(percentageToMidX: percentageToMidX, scale: scale)
    }
    
    func getlayoutAttributesIndex(velocity: CGPoint, proposedContentOffset: CGPoint, contentOffset: CGPoint) -> IndexPath? {
        let isForward = proposedContentOffset.x > contentOffset.x
        let xVelocity = abs(velocity.x)
        
        if xVelocity == 0 {
            if indexPath == startOfScrollIndex {
                return startOfScrollIndex
            } else {
                return indexPath
            }
        } else if isForward {
            return IndexPath(item: startOfScrollIndex.item + 1, section: 0)
        } else {
            return IndexPath(item: startOfScrollIndex.item - 1, section: 0)
        }
    }
    
    func getTargetContentOffsetPoint(x: CGFloat, y: CGFloat) -> CGPoint {
        let centerX = collectionViewWidth / 2.0
        return CGPoint(x: x - centerX, y: y)
    }
    
    /// Once the scale is greater than the mid scale, we know that the collectionview will snap to this item. Therefore it will be the current index.
    /// Example: max scale is 1, and the min is 0.8, the middle scale will be 0.9. Once an items scale is greater than this, we have our new current index.
    func updateCurrentIndexPathIfNeeded(to indexPath: IndexPath, using scale: CGFloat) {
        guard scale > midScale else { return }
        self.indexPath = indexPath
    }
}
