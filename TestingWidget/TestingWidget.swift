//
//  TestingWidget.swift
//  TestingWidget
//
//  Created by Richard Witherspoon on 7/11/23.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date())
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        var entries: [SimpleEntry] = []
        
        // Generate a timeline consisting of five entries an hour apart, starting from the current date.
        let currentDate = Date()
        for hourOffset in 0 ..< 5 {
            let entryDate = Calendar.current.date(byAdding: .hour, value: hourOffset, to: currentDate)!
            let entry = SimpleEntry(date: entryDate)
            entries.append(entry)
        }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
}

struct TestingWidgetEntryView : View {
    var entry: Provider.Entry
    @AppStorage("count", store: .shared) var count = 0
    
    var body: some View {
        HStack(spacing: 6) {
            Button(intent: AddCountIntent()){
                Text("Count: \(count)")
            }
            .transition(.scale.combined(with: .opacity))
//            .widgetURL(URL(string: "testing://count1"))
            
            Button(intent: ResetCountIntent()){
                Text("Reset")
            }
//            .widgetURL(URL(string: "testing://count2"))
            
//            Text("Count: \(count)")
//                .widgetURL(URL(string: "testing://count1"))
//            Text("Reset")
//                .widgetURL(URL(string: "testing://count2"))
        }
        .font(.system(size: 10))
    }
}

struct TestingWidget: Widget {
    let kind: String = "TestingWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TestingWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("My Widget")
        .description("This is an example widget.")
        .supportedFamilies([.systemSmall, .accessoryRectangular])
    }
}

struct TestingWidget_Previews: PreviewProvider {
    static var previews: some View {
        TestingWidgetEntryView(entry: SimpleEntry(date: Date()))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}

import AppIntents

struct AddCountIntent: AppIntent {
    static var title: LocalizedStringResource = "Add count"
    static var openAppWhenRun: Bool = false
    
    func perform() async throws -> some IntentResult {
        let count = UserDefaults.shared.integer(forKey: "count")
        let newValue = count + 1
        UserDefaults.shared.setValue(newValue, forKey: "count")
        return .result()
    }
}

struct ResetCountIntent: AppIntent {
    static var title: LocalizedStringResource = "Add count"
    
    func perform() async throws -> some IntentResult {
        UserDefaults.shared.setValue(0, forKey: "count")
        return .result()
    }
}
