//
//  TestingWidget.swift
//  TestingWidget
//
//  Created by Richard Witherspoon on 7/11/23.
//

import WidgetKit
import SwiftUI

struct TestingWidget: Widget {
    let kind: String = "TestingWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TestingWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
        .supportedFamilies([.systemSmall])
    }
}
