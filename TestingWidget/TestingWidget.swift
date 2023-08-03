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
                AppIntentConfiguration(
                    kind: kind,
                    intent: SelectFavouriteIceCream.self,
                    provider: Provider()) { entry in
        
//                IntentConfiguration(
//                    kind: kind,
//                    intent: ScanIntent.self,
//                    provider: Provider()) { entry in
        
        
//        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TestingWidgetEntryView(entry: entry)
        }
            .configurationDisplayName("My Widget")
            .description("This is an example widget.")
            .supportedFamilies([.systemSmall])
    }
}


import AppIntents

struct SelectFavouriteIceCream: AppIntent, WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Select favourite ice cream"
    static var description = IntentDescription("Selects the user favourite ice cream")
 
//    @Parameter(title: "IceCream", optionsProvider: IceCreamOptionsProvider())
//    var iceCream: String
// 
//    @Parameter(title: "Site", optionsProvider: ToppingOptionsProvider())
//    var topping: String
}


//struct IceCreamOptionsProvider: DynamicOptionsProvider {
//    func results() async throws -> [String] {
//        ["Vanilla", "Strawberry", "Lemon"]
//    }
//}
//
//struct ToppingOptionsProvider: DynamicOptionsProvider {
//    func results() async throws -> [String] {
//        ["Chocolate Sirup", "Sprinkles", "Peanut Butter", "Toasted Coconut Flakes"]
//    }
//}
//
