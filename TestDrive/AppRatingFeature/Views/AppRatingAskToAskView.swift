//
//  AppRatingAskToAskView.swift
//  AppRatingFeature
//
//  Created on 9/25/25.
//

import SwiftUI

/// The ask-to-ask view for app rating with 5-star selection
public struct AppRatingAskToAskView: View {
    @State private var selectedRating: Int = 0
    @State private var hasInteracted = false
    
    private let analytics: AppRatingAnalyticsRecording
    private let useCase: PresentAppRatingAskToAskUseCase
    private let onDismiss: () -> Void
    
    public init(
        analytics: AppRatingAnalyticsRecording = ConsoleAppRatingAnalyticsRecorder(),
        useCase: PresentAppRatingAskToAskUseCase,
        onDismiss: @escaping () -> Void
    ) {
        self.analytics = analytics
        self.useCase = useCase
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        ZStack {
            // Dark background that prevents dismissal
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .allowsHitTesting(true) // Prevents tap-through
            
            VStack(spacing: 0) {
                Spacer()
                
                // Content card
                VStack(spacing: 30) {
                    // App Icon
                    Image("AppIcon1024-TODO")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60)
                        .cornerRadius(12)
                    
                    // Title
                    Text("Are you loving Photo Recorder?")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    // Star rating (acts as submit button)
                    StarRatingView(rating: $selectedRating) { rating in
                        analytics.recordEvent(.starsSelected(count: rating))
                        
                        Task {
                            await submitRating(rating)
                        }
                    }
                }
                .padding(40)
                .background(Color.blue)
                .cornerRadius(20)
                .padding()
                
                Spacer()
            }
        }
        .onAppear {
            analytics.recordEvent(.askToAskViewed)
            useCase.recordPromptViewed()
        }
    }
    
    private func submitRating(_ rating: Int) async {
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        // Handle rating through use case
        useCase.handleRatingSelection(rating)
        
        try? await Task.sleep(for: .seconds(1))
        onDismiss()
    }
}

#Preview {
    AppRatingAskToAskView(
        analytics: ConsoleAppRatingAnalyticsRecorder(),
        useCase: MockPresentAppRatingAskToAskUseCase(),
        onDismiss: {}
    )
}
