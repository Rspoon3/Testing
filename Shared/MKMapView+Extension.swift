//
//  MKMapView+Extension.swift
//  Testing
//
//  Created by Richard Witherspoon on 2/3/21.
//

import Foundation
import MapKit


extension MKMapView {
    func animatedZoom(zoomRegion:MKCoordinateRegion, duration:TimeInterval) {
        MKMapView.animate(withDuration: duration){
            self.setRegion(zoomRegion, animated: true)
        }
    }
}
