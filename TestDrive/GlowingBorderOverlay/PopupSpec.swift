//
//  PopupSpec.swift
//  TestDrive
//

import SwiftUI

/// The animation a popup applies while it's on screen.
enum PopupAnimation: CaseIterable {
    /// Opacity oscillates between dim and full.
    case flash
    /// Body and button scale together with a heartbeat-style pulse.
    case pulse
    /// Whole window rotates back and forth a couple of degrees.
    case shake
    /// Hue rotates through the spectrum.
    case rainbow
    /// Title bar color flickers between two colors.
    case marquee
}

/// One unique popup in the "90s virus" catalog. Self-contained styling + copy
/// — colors, fonts, button label, animation style all live here so the runtime
/// just needs to render one of these without conditional formatting logic.
struct PopupSpec: Identifiable, Hashable {
    let id: String
    let title: String
    let body: String
    let buttonLabel: String
    let titleBarColor: Color
    let titleTextColor: Color
    let bodyBackground: Color
    let bodyText: Color
    let buttonBackground: Color
    let buttonText: Color
    let bodyFont: Font
    let animation: PopupAnimation

    // MARK: - Catalog

    /// The full set of "fake virus" popups that can appear in the overlay.
    /// Mixes household easter eggs (Nigerian prince, extended warranty) with
    /// classic late-90s adware tropes (Punch the Monkey, registry cleaner,
    /// the 1,000,000th visitor banner).
    static let catalog: [PopupSpec] = [
        PopupSpec(
            id: "nigerianPrince",
            title: "URGENT — PRINCE TUNDE",
            body: """
            DEAR FRIEND,

            I am Prince Tunde of Nigeria. My late
            father has left me $47,000,000 USD in
            gold reserves. I need your help to
            transfer the funds to safety.

            Please reply with your bank details so
            we may proceed at once. God bless you.
            """,
            buttonLabel: "REPLY NOW",
            titleBarColor: Color(red: 0.13, green: 0.10, blue: 0.55),
            titleTextColor: .white,
            bodyBackground: Color(red: 1.0, green: 1.0, blue: 0.85),
            bodyText: .black,
            buttonBackground: .yellow,
            buttonText: .blue,
            bodyFont: .system(.body, design: .serif),
            animation: .flash
        ),
        PopupSpec(
            id: "carWarranty",
            title: "VEHICLE WARRANTY — ACT NOW",
            body: """
            We've been trying to reach you about
            your car's EXTENDED warranty.

            This is your FINAL NOTICE before
            coverage lapses. Press the button
            below to speak with a specialist.
            """,
            buttonLabel: "PRESS 1 TO ACT",
            titleBarColor: .red,
            titleTextColor: .white,
            bodyBackground: .white,
            bodyText: .red,
            buttonBackground: .red,
            buttonText: .white,
            bodyFont: .system(.body, design: .default).weight(.bold),
            animation: .pulse
        ),
        PopupSpec(
            id: "millionthVisitor",
            title: "🎉 CONGRATULATIONS 🎉",
            body: """
            YOU ARE THE 1,000,000th VISITOR!

            You have been selected to receive a
            brand new iPod Nano™. Click the
            button below to claim your prize!

            ✨ NO PURCHASE NECESSARY ✨
            """,
            buttonLabel: "CLAIM PRIZE",
            titleBarColor: Color(red: 1.0, green: 0.65, blue: 0.0),
            titleTextColor: .white,
            bodyBackground: .yellow,
            bodyText: Color(red: 0.55, green: 0.0, blue: 0.55),
            buttonBackground: .green,
            buttonText: .white,
            bodyFont: .system(.body, design: .rounded).weight(.bold),
            animation: .rainbow
        ),
        PopupSpec(
            id: "virusDetected",
            title: "⚠ WINDOWS SECURITY ALERT ⚠",
            body: """
            VIRUS DETECTED!

            Your computer has 47 viruses.
            Personal data may be at risk.

            DO NOT TURN OFF YOUR COMPUTER.
            Run a full scan immediately to
            remove all threats.
            """,
            buttonLabel: "SCAN NOW",
            titleBarColor: Color(red: 0.0, green: 0.0, blue: 0.6),
            titleTextColor: .white,
            bodyBackground: Color(white: 0.86),
            bodyText: .black,
            buttonBackground: Color(red: 0.0, green: 0.5, blue: 0.0),
            buttonText: .white,
            bodyFont: .system(.body, design: .monospaced),
            animation: .flash
        ),
        PopupSpec(
            id: "hotSingles",
            title: "💋 Hot Singles Near You",
            body: """
            Lonely tonight?

            There are 12 singles in your
            area looking to chat right now!

            Sign up free for 30 days — no
            credit card required.
            """,
            buttonLabel: "MEET LOCALS",
            titleBarColor: .pink,
            titleTextColor: .white,
            bodyBackground: Color(red: 1.0, green: 0.85, blue: 0.95),
            bodyText: Color(red: 0.6, green: 0.0, blue: 0.3),
            buttonBackground: Color(red: 0.9, green: 0.2, blue: 0.55),
            buttonText: .white,
            bodyFont: .system(.body, design: .rounded),
            animation: .marquee
        ),
        PopupSpec(
            id: "punchMonkey",
            title: "🐵 PUNCH THE MONKEY",
            body: """
            Punch the monkey to win
            a free trip to Hawaii!

            Score 100,000 points or
            more and you qualify!

            🌺 OFFICIAL WINNER! 🌺
            """,
            buttonLabel: "PUNCH NOW",
            titleBarColor: .purple,
            titleTextColor: .yellow,
            bodyBackground: Color(red: 0.55, green: 0.85, blue: 0.0),
            bodyText: .black,
            buttonBackground: .orange,
            buttonText: .white,
            bodyFont: .system(.body, design: .rounded).weight(.bold),
            animation: .shake
        ),
        PopupSpec(
            id: "registryCleaner",
            title: "PC Speed-Up — Registry Cleaner",
            body: """
            Your PC contains 1,847 registry
            errors slowing it down.

            Our certified Windows™ engineers
            can fix all of these issues with
            ONE CLICK. Your computer will run
            up to 300% faster!
            """,
            buttonLabel: "FIX ALL ERRORS",
            titleBarColor: Color(white: 0.4),
            titleTextColor: .white,
            bodyBackground: .white,
            bodyText: .black,
            buttonBackground: Color(red: 0.1, green: 0.55, blue: 0.15),
            buttonText: .white,
            bodyFont: .system(.body),
            animation: .pulse
        ),
        PopupSpec(
            id: "downloadComplete",
            title: "Download Complete",
            body: """
            Smiley_Central_Toolbar.exe
            has finished downloading.

            Install Smiley Central to access
            over 1,000 emoticons in your
            email, browser, and chat windows!

            By installing you agree to the
            Terms & Conditions.
            """,
            buttonLabel: "INSTALL NOW",
            titleBarColor: Color(red: 0.0, green: 0.45, blue: 0.85),
            titleTextColor: .white,
            bodyBackground: .white,
            bodyText: .black,
            buttonBackground: Color(red: 0.0, green: 0.45, blue: 0.85),
            buttonText: .white,
            bodyFont: .system(.body),
            animation: .flash
        ),
        PopupSpec(
            id: "macSlow",
            title: "Your Mac is running slow!",
            body: """
            We've detected your Mac is
            running 64% slower than normal.

            Click below to download
            MacKeeper-Pro™ and restore
            full performance instantly.

            (Recommended by Apple™*)
            """,
            buttonLabel: "DOWNLOAD",
            titleBarColor: .red,
            titleTextColor: .white,
            bodyBackground: Color(white: 0.95),
            bodyText: .red,
            buttonBackground: Color(red: 0.85, green: 0.1, blue: 0.1),
            buttonText: .white,
            bodyFont: .system(.body, design: .default).weight(.semibold),
            animation: .pulse
        ),
        PopupSpec(
            id: "freeIpod",
            title: "GET A FREE iPod",
            body: """
            Limited time offer!

            Complete one simple survey
            and we'll ship you a brand
            new iPod, completely FREE.

            No catch. No shipping fees.
            """,
            buttonLabel: "GET MY iPod",
            titleBarColor: .black,
            titleTextColor: .white,
            bodyBackground: .white,
            bodyText: .black,
            buttonBackground: Color(red: 0.0, green: 0.6, blue: 0.0),
            buttonText: .white,
            bodyFont: .system(.body, design: .rounded),
            animation: .rainbow
        ),
        PopupSpec(
            id: "irsAudit",
            title: "IRS — IMMEDIATE ACTION REQUIRED",
            body: """
            This is an automated notice from
            the Internal Revenue Service.

            You owe $4,287.00 in back taxes.
            Failure to pay within 24 hours
            will result in arrest.

            Please pay via Apple gift cards.
            """,
            buttonLabel: "PAY NOW",
            titleBarColor: Color(red: 0.0, green: 0.2, blue: 0.55),
            titleTextColor: .white,
            bodyBackground: Color(white: 0.92),
            bodyText: .black,
            buttonBackground: Color(red: 0.7, green: 0.0, blue: 0.0),
            buttonText: .white,
            bodyFont: .system(.body, design: .monospaced),
            animation: .marquee
        ),
        PopupSpec(
            id: "errorCantun",
            title: "Error",
            body: """
            Cannot find Cancun.

            Would you like to take a
            7-day, all-inclusive vacation
            to the Bahamas instead?

            (Cost: $0.00 — limited time!)
            """,
            buttonLabel: "YES PLEASE",
            titleBarColor: Color(white: 0.7),
            titleTextColor: .black,
            bodyBackground: .white,
            bodyText: .black,
            buttonBackground: Color(white: 0.85),
            buttonText: .black,
            bodyFont: .system(.body),
            animation: .shake
        )
    ]
}
