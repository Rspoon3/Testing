//
//  CarouselLayoutAttributes.swift
//  FetchRewards
//
//  Created by Richard Witherspoon on 1/27/23.
//  Copyright © 2023 Fetch Rewards, LLC. All rights reserved.
//

import UIKit

final class CarouselLayoutAttributes: UICollectionViewLayoutAttributes {

    var percentageToMidX: CGFloat = 0
    
    override func isEqual(_ object: Any?) -> Bool {
        guard let object = object as? CarouselLayoutAttributes else {
            return false
        }
        
        var isEqual = super.isEqual(object)
        isEqual = isEqual && (self.percentageToMidX == object.percentageToMidX)
        return isEqual
    }
    
    override func copy(with zone: NSZone? = nil) -> Any {
        guard let copy = super.copy(with: zone) as? CarouselLayoutAttributes else {
            return super.copy(with: zone)
        }
        
        copy.percentageToMidX = self.percentageToMidX
        return copy
    }
}
