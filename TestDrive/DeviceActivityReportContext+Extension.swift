//
//  DeviceActivityReportContext+Extension.swift
//  Testing
//
//  Created by Ricky Witherspoon on 4/15/25.
//

import SwiftUI
import DeviceActivity

extension DeviceActivityReport.Context {
    // If your app initializes a DeviceActivityReport with this context, then the system will use
    // your extension's corresponding DeviceActivityReportScene to render the contents of the
    // report.
    static let totalActivity = Self("Total Activity")
    static let home = Self("Home Report")
    static let widget = Self("Widget")
    static let moreInsights = Self("More Insights")
}
