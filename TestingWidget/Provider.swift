//
//  Provider.swift
//  Testing (iOS)
//
//  Created by Richard Witherspoon on 7/17/23.
//

import Foundation
import SwiftUI
import WidgetKit

//struct Provider: TimelineProvider {
//    func placeholder(in context: Context) -> SimpleEntry {
//        SimpleEntry(date: .now)
//    }
//    
//    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
//        let entry = SimpleEntry(date: .now)
//        completion(entry)
//    }
//    
//    func getTimeline(in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> ()) {
//        var entries: [SimpleEntry] = []
//        
//        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
//        let currentDate = Date()
//        for hourOffset in 0 ..< 5 {
//            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
//            let entry = SimpleEntry(date: entryDate)
//            entries.append(entry)
//        }
//        
//        let timeline = Timeline(entries: entries, policy: .atEnd)
//        completion(timeline)
//    }
//}
//
//
//extension Provider: IntentTimelineProvider {
//    func getSnapshot(for configuration: ScanIntent, in context: Context, completion: @escaping (SimpleEntry) -> Void) {
//        // `StaticConfiguration` and `IntentConfiguration` consumers of `PointsProvider` should both have the same data source/entries
//        getSnapshot(in: context, completion: completion)
//    }
//
//    func getTimeline(for configuration: ScanIntent, in context: Context, completion: @escaping (Timeline<SimpleEntry>) -> Void) {
//        // `StaticConfiguration` and `IntentConfiguration` consumers of `PointsProvider` should both have the same data source/entries
//        getTimeline(in: context, completion: completion)
//    }
//}


struct Provider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: .now)
    }

    func snapshot(for configuration: SelectFavouriteIceCream, in context: Context) async -> SimpleEntry {
        return  SimpleEntry(date: .now)
    }
    
    func timeline(for configuration: SelectFavouriteIceCream, in context: Context) async -> Timeline<SimpleEntry> {
        var entries: [SimpleEntry] = []
        
        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate)
            entries.append(entry)
        }
        
        return Timeline(entries: entries, policy: .atEnd)
    }
}
