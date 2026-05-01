//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI
import Charts

struct Item: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let count = Int.random(in: 1..<10)
}

struct ContentView: View {
    @State private var timePeriod: TimePeriod = .yearly
    @State var items = [Item]()
    @State private var scrollPosition = Date.now
    @State private var selectedItem: Item?
    @State private var plotWidth: CGFloat = 0

//    private var chartXVisibleDomain: Date {
//        switch timePeriod {
//        case .weekly: Calendar.current.date(byAdding: .weekOfYear, value: -5, to: .now)!
//        case .monthly: Calendar.current.date(byAdding: .month, value: -5, to: .now)!
//        case .yearly: Calendar.current.date(byAdding: .year, value: -2, to: .now)!
//        }
//    }

    func updateItems() {
        items = (0..<20).map { i -> Item in
            let component = switch timePeriod {
            case .daily: Calendar.Component.day
            case .weekly: Calendar.Component.weekOfYear
            case .monthly: Calendar.Component.month
            case .yearly: Calendar.Component.year
            }
            
            return Item(
                date: Calendar.current.date(
                    byAdding: component,
                    value: -i,
                    to: .now
                )!.startOfDay
            )
        }
        
        print(items)
    }
    
    var body: some View {
        VStack {
            Picker("Time Period", selection: $timePeriod) {
                ForEach(TimePeriod.allCases, id: \.self) { period in
                    Text(period.rawValue)
                        .tag(period)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .onChange(of: timePeriod) { updateItems() }
            .onAppear(perform: updateItems)
            
            Text(scrollPosition.formatted())
            
            Chart(items) { item in
                BarMark(
                    x: .value(
                        timePeriod.rawValue,
                        item.date,
                        unit: timePeriod.calendarComponents
                    ),
                    y: .value("Count", item.count)
                )
            }
            .chartScrollableAxes(.horizontal)
//            .chartXVisibleDomain(length: abs(chartXVisibleDomain.timeIntervalSinceNow))
            .chartScrollPosition(x: $scrollPosition)
            .chartScrollTargetBehavior(
                .valueAligned(
                    matching: timePeriod.snapInterval, // snapping behavior (not working?)
                    majorAlignment: .matching(timePeriod.snapInterval)
                )
            )
            .chartXAxis {
                AxisMarks(values: .stride(by: timePeriod.calendarComponents)) { value in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(
                        format: timePeriod.dateFormatStyle,
                        centered: true
                    )
                }
            }
            .chartOverlay { proxy in
                GeometryReader { geo in
                    Rectangle().fill(.clear).contentShape(Rectangle())
                        .gesture(
                            SpatialTapGesture()
                                .onEnded { value in
                                    let element = findElement(location: value.location, proxy: proxy, geometry: geo)
                                    if selectedItem?.date == element?.date {
                                        // If tapping the same element, clear the selection.
                                        selectedItem = nil
                                    } else {
                                        selectedItem = element
                                    }
                                }
                                .exclusively(
                                    before: DragGesture()
                                        .onChanged { value in
                                            selectedItem = findElement(location: value.location, proxy: proxy, geometry: geo)
                                        }
                                )
                        )
                }
            }
            .chartBackground { proxy in
                ZStack(alignment: .topLeading) {
                    GeometryReader { geo in
                        if let selectedItem {
                            let dateInterval = Calendar.current.dateInterval(of: .day, for: selectedItem.date)!
                            let startPositionX1 = proxy.position(forX: dateInterval.start) ?? 0

                            let lineX = startPositionX1 + geo[proxy.plotFrame!].origin.x
                            let lineHeight = geo[proxy.plotAreaFrame].maxY
                            let boxWidth: CGFloat = 100
                            let boxOffset = max(0, min(geo.size.width - boxWidth, lineX - boxWidth / 2))

                            Rectangle()
                                .fill(.red)
                                .frame(width: 2, height: lineHeight)
                                .position(x: lineX, y: lineHeight / 2)

                            VStack(alignment: .center) {
                                Text("\(selectedItem.date, format: .dateTime.year().month().day())")
                                    .font(.callout)
                                    .foregroundStyle(.secondary)
                                Text("\(selectedItem.count, format: .number)")
                                    .font(.title2.bold())
                                    .foregroundColor(.primary)
                            }
                            .accessibilityElement(children: .combine)
                            .frame(width: boxWidth, alignment: .leading)
                            .background {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(.background)
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(.quaternary.opacity(0.7))
                                }
                                .padding(.horizontal, -8)
                                .padding(.vertical, -4)
                            }
                            .offset(x: boxOffset)
                        }
                    }
                }
            }
        }
        .padding()
    }
    
    private func findElement(location: CGPoint, proxy: ChartProxy, geometry: GeometryProxy) -> Item? {
        let relativeXPosition = location.x - geometry[proxy.plotFrame!].origin.x
        if let date = proxy.value(atX: relativeXPosition) as Date? {
            // Find the closest date element.
            var minDistance: TimeInterval = .infinity
            var index: Int? = nil
            for salesDataIndex in items.indices {
                let nthSalesDataDistance = items[salesDataIndex].date.distance(to: date)
                if abs(nthSalesDataDistance) < minDistance {
                    minDistance = abs(nthSalesDataDistance)
                    index = salesDataIndex
                }
            }
            if let index {
                return items[index]
            }
        }
        return nil
    }
}


#Preview {
    ContentView()
}

extension Date {
    var startOfDay: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    var startOfMonth: Date? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)
        
        return  calendar.date(from: components)
    }
}
