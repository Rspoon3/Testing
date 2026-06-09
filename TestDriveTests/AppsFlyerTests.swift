//
//  AppsFlyerTests.swift
//  TestDriveTests
//
//  Created by Ricky Witherspoon on 6/9/26.
//

import Testing
@testable import TestDrive

@Suite("AppsFlyer Tests")
struct AppsFlyerTests {
    private let referralCode = "RICKY1"

    @Test("The conversion listener returns the referral code")
    func conversionReturnsCode() {
        #expect(AppsFlyerManager().onConversionDataSuccess() == referralCode)
    }

    @Test("The app-open attribution listener returns the referral code")
    func attributionReturnsCode() {
        #expect(AppsFlyerManager().onAppOpenAttribution() == referralCode)
    }

    @Test("The deep link listener returns the referral code")
    func deeplinkReturnsCode() {
        #expect(AppsFlyerManager().onDeeplink() == referralCode)
    }
}
