//
//  SettingsView.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 10/4/25.
//

#if DEBUG

import SwiftUI

struct SettingsView: View {
    private let appRatingUseCase: PresentAppRatingAskToAskUseCase
    private let appRatingUserStore: AppRatingUserStore
    private let appRatingEligibilityRepository: AppRatingEligibilityRepository
    private let appRatingViewedStore: AppRatingViewedStore
    
    // MARK: - Initializer
    
    init(
        appRatingUseCase: PresentAppRatingAskToAskUseCase? = nil,
        appRatingUserStore: AppRatingUserStore = AppRatingUserStoreLive.shared,
        appRatingViewedStore: AppRatingViewedStore = AppRatingViewedStoreLive(),
        appRatingEligibilityRepository: AppRatingEligibilityRepository? = nil
    ) {
        self.appRatingUserStore = appRatingUserStore
        self.appRatingViewedStore = appRatingViewedStore
        
        let appRatingEligibilityRepositoryLive = AppRatingEligibilityRepositoryLive(
            viewedStore: appRatingViewedStore,
            userStore: appRatingUserStore
        )
        
        let eligibilityRepository = appRatingEligibilityRepository ?? appRatingEligibilityRepositoryLive
        self.appRatingEligibilityRepository = eligibilityRepository

        if let appRatingUseCase {
            self.appRatingUseCase = appRatingUseCase
        } else {
            self.appRatingUseCase = PresentAppRatingAskToAskUseCaseLive(
                eligibilityRepository: eligibilityRepository,
                userStore: appRatingUserStore
            )
        }
    }
    
    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            AppRatingDebugView(
                eligibilityRepository: appRatingEligibilityRepository,
                userStore: appRatingUserStore,
                viewedStore: appRatingViewedStore,
                useCase: appRatingUseCase
            )
        }
    }
}

#Preview {
    SettingsView()
}
#endif
