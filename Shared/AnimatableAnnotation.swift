//
//  AnimatableAnnotation.swift
//  Testing
//
//  Created by Richard Witherspoon on 2/3/21.
//

import Foundation
import MapKit

class AnimatableAnnotation : NSObject, MKAnnotation {
    dynamic var coordinate: CLLocationCoordinate2D
    dynamic var title: String?
    dynamic var subtitle: String?

    init(coordinate: CLLocationCoordinate2D, title: String? = nil, subtitle: String? = nil) {
        self.coordinate = coordinate
        self.title = title
        self.subtitle = subtitle

        super.init()
    }
}
