//
//  CarouselLayout.swift
//  FetchRewards
//
//  Created by Richard Witherspoon on 1/27/23.
//  Copyright © 2023 Fetch Rewards, LLC. All rights reserved.
//

import UIKit

final class CarouselLayout: UICollectionViewFlowLayout {
    let model: CarouselLayoutModel
    
    // MARK: - Initializer
    
    init(model: CarouselLayoutModel) {
        self.model = model
        super.init()
        
        scrollDirection = .horizontal
    }
    
    required init?(coder aDecoder: NSCoder) {
        return nil
    }
    
    // MARK: - Layout
    
    override class var layoutAttributesClass: AnyClass {
        return CarouselLayoutAttributes.self
    }
    
    override func prepare() {
        guard let collectionView else { return }
        
        itemSize = model.cellSize
        minimumLineSpacing = model.interGroupSpacing
        sectionInset = model.getSectionInset(collectionViewFrame: collectionView.frame, adjustedContentInset: collectionView.adjustedContentInset)
        
        super.prepare()
    }
    
    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard
            let collectionView,
            let rectAttributes = super.layoutAttributesForElements(in: rect)?.compactMap({ $0.copy() as? UICollectionViewLayoutAttributes })
        else {
            return nil
        }
        
        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.frame.size)
        
        for attributes in rectAttributes where attributes.frame.intersects(visibleRect) {
            let spacing = model.performScaleCalulations(midX: attributes.frame.midX,
                                                        xOffset: collectionView.contentOffset.x)
            
            if let attributes = attributes as? CarouselLayoutAttributes {
                attributes.percentageToMidX = spacing.percentageToMidX
            }
            
            model.updateCurrentIndexPathIfNeeded(to: attributes.indexPath, using: spacing.scale)

            attributes.transform = CGAffineTransform(scaleX: spacing.scale, y: spacing.scale)
        }
        
        return rectAttributes
    }
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard
            let collectionView,
            let desiredIndex = model.getlayoutAttributesIndex(velocity: velocity, proposedContentOffset: proposedContentOffset, contentOffset: collectionView.contentOffset),
            let desiredAttribute = collectionView.layoutAttributesForItem(at: desiredIndex)
        else {
            return super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity)
        }
        
        return model.getTargetContentOffsetPoint(x: desiredAttribute.center.x, y: proposedContentOffset.y)
    }
    
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        // Invalidate layout so that every cell get a chance to be zoomed when it reaches the center of the screen
        return true
    }
    
    override func invalidationContext(forBoundsChange newBounds: CGRect) -> UICollectionViewLayoutInvalidationContext {
        guard let context = super.invalidationContext(forBoundsChange: newBounds) as? UICollectionViewFlowLayoutInvalidationContext else {
            return super.invalidationContext(forBoundsChange: newBounds)
        }
        
        context.invalidateFlowLayoutDelegateMetrics = newBounds.size != collectionView?.bounds.size
        return context
    }
}
