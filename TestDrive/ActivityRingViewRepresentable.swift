//
//  ActivityRingViewRepresentable.swift
//  Testing
//
//  Created by Ricky Witherspoon on 4/12/25.
//


import SwiftUI
import HealthKit
import HealthKitUI

struct ActivityRingViewRepresentable: UIViewRepresentable {
    let summary: HKActivitySummary

    func makeUIView(context: Context) -> HKActivityRingView {
        let view = HKActivityRingView()
        view.setActivitySummary(summary, animated: false)
        return view
    }

    func updateUIView(_ uiView: HKActivityRingView, context: Context) {
        uiView.setActivitySummary(summary, animated: true)
    }
}
