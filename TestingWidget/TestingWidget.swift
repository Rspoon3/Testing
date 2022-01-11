//
//  TestingWidget.swift
//  TestingWidget
//
//  Created by Richard Witherspoon on 1/7/22.
//

import WidgetKit
import SwiftUI

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: .now)
    }
    
    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: .now)
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let calendar = Calendar.current
        let oneMinute: TimeInterval = 60
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: Date())
        var currentMinute = calendar.date(from: components)!
        let thirtyMinutes = currentMinute.addingTimeInterval(60 * 30)
        let twentyMinutes = currentMinute.addingTimeInterval(60 * 20)
        var entries = [SimpleEntry]()

        while currentMinute < min(SimpleEntry.arrival, thirtyMinutes){
            let random = Int.random(in: 1...6)
            let entry = SimpleEntry(date: currentMinute, imageNumber: random)
            currentMinute += oneMinute
            entries.append(entry)
            print(currentMinute, random)
        }

        let timeline = Timeline(entries: entries, policy: .after(twentyMinutes))
        completion(timeline)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let imageNumber: Int
    
    init(date: Date, imageNumber: Int = 1){
        self.date = date
        self.imageNumber = imageNumber
    }
    
    static var arrival: Date = {
        var dateComponents = DateComponents()
        dateComponents.year = 2022
        dateComponents.month = 1
        dateComponents.day = 8
        dateComponents.timeZone = TimeZone(abbreviation: "EST")
        dateComponents.hour = 15
        dateComponents.minute = 25
        
        let arrival = Calendar.current.date(from: dateComponents)
        return arrival!
    }()
    
    var hours: Int{
        let diffComponents = Calendar.current.dateComponents([.hour], from: date, to: SimpleEntry.arrival)
        return (diffComponents.hour ?? 0)
    }
    
    var minutes: Int{
        let diffComponents = Calendar.current.dateComponents([.hour, .minute], from: date, to: SimpleEntry.arrival)
        let minutes = (diffComponents.minute ?? 0)
        
        if minutes > 0{
            return minutes - 1
        } else {
            return minutes
        }
    }
}

struct TestingWidgetEntryView : View {
    var entry: Provider.Entry
    
    var body: some View {
        ZStack(alignment: .bottomLeading){
            GeometryReader{ geo in
                Image("Aimee\(entry.imageNumber)")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
            }
            LinearGradient(colors: [.clear, .black.opacity(0.4)], startPoint: .top, endPoint: .bottom)
            VStack(alignment: .leading){
                Text("\(entry.hours) hours")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("\(entry.minutes) minutes")
                    .font(.title3)
                    .fontWeight(.semibold)
                Text("Aimee ❤️🛬")
                    .font(.subheadline)
            }
            .foregroundColor(.white)
            .padding(.all, 8)
        }
    }
}

@main
struct TestingWidget: Widget {
    let kind: String = "TestingWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TestingWidgetEntryView(entry: entry)
        }
        .supportedFamilies([.systemSmall, .systemLarge])
        .configurationDisplayName("Aimee Countdown")
        .description("A countdown until when Aimee arrives.")
    }
}

struct TestingWidget_Previews: PreviewProvider {
    static var previews: some View {
        TestingWidgetEntryView(entry: SimpleEntry(date: .now))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
