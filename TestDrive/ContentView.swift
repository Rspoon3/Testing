//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI
import AppTrackingTransparency
import AdSupport

struct ContentView: View {
    var body: some View {
        Button("Track") {
            requestAppTrackingPermission()
            
            if ATTrackingManager.trackingAuthorizationStatus == .authorized {
                let idfa = ASIdentifierManager.shared().advertisingIdentifier
                print("IDFA: \(idfa)")
            } else {
                print("Tracking not authorized")
            }
        }
    }
    
    private func requestAppTrackingPermission() {
        DispatchQueue.main.async {
            ATTrackingManager.requestTrackingAuthorization { status in
                switch status {
                case .authorized:
                    print("Tracking authorized")
                case .denied:
                    print("Tracking denied")
                case .notDetermined:
                    print("Tracking not determined")
                case .restricted:
                    print("Tracking restricted")
                @unknown default:
                    print("Unknown tracking status")
                }
            }
        }
    }
}


#Preview {
    ContentView()
}
