//
//  PrivacyScreen.swift
//  Testing (iOS)
//
//  Created by Ricky on 12/1/24.
//


import SwiftUI
import CoreLocation


struct PrivacyScreen: View {
    @StateObject private var locationManager = LocationManager()
    @State private var isAnimating = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        VStack(spacing: 30) {
            // Animated Icon
            ZStack {
                Circle()
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [.blue, .purple, .pink, .blue]),
                            center: .center
                        ),
                        lineWidth: 15
                    )
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(
                        Animation.linear(duration: 4).repeatForever(autoreverses: false),
                        value: isAnimating
                    )
                
                Image(systemName: "location.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)
            }
            .onAppear {
                isAnimating = true
            }
            
            // Playful Title
            Text(locationManager.permissionStatus == .authorizedAlways || locationManager.permissionStatus == .authorizedWhenInUse ? "You're All Set!" : "Help Us Help You!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(locationManager.permissionStatus == .authorizedAlways || locationManager.permissionStatus == .authorizedWhenInUse ? .green : .primary)
            
            // Fun Description
            Text(locationManager.permissionStatus == .authorizedAlways || locationManager.permissionStatus == .authorizedWhenInUse ?
                 "Now we can track where you've collected license plates. Time to hit the road!" :
                    "We need your location to save where you've collected license plates. It's like geocaching, but cooler!")
            .multilineTextAlignment(.center)
            .padding(.horizontal)
            .font(.headline)
            
            Spacer()
            
            // Action Buttons
            if locationManager.permissionStatus == .notDetermined {
                Button {
                    locationManager.requestPermission()
                    dismiss()
                } label: {
                    Text("Let's Go!")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                }
                .padding(.horizontal)
            } else if locationManager.permissionStatus == .authorizedAlways || locationManager.permissionStatus == .authorizedWhenInUse {
                Text("Location Access Granted! 🎉")
                    .foregroundColor(.green)
                    .font(.headline)
            } else {
                VStack(spacing: 10) {
                    Text("Access Denied 😢")
                        .foregroundColor(.red)
                        .font(.headline)
                    
                    Text("Enable location access in settings to unlock all the fun!")
                        .multilineTextAlignment(.center)
                        .font(.subheadline)
                    
                    Button {
                        openAppSettings()
                    } label: {
                        Text("Open Settings")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .shadow(radius: 5)
                    }
                    .padding(.horizontal)
                }
            }
        }
        .padding()
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.pink.opacity(0.2), Color.blue.opacity(0.2)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}


#Preview {
    PrivacyScreen()
}

// Location Manager
class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var permissionStatus: CLAuthorizationStatus = .notDetermined
    
    override init() {
        super.init()
        locationManager.delegate = self
        permissionStatus = locationManager.authorizationStatus
    }
    
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.permissionStatus = manager.authorizationStatus
        }
    }
}

// Helper to Open App Settings
func openAppSettings() {
    guard let url = URL(string: UIApplication.openSettingsURLString),
          UIApplication.shared.canOpenURL(url) else { return }
    UIApplication.shared.open(url, options: [:], completionHandler: nil)
}
