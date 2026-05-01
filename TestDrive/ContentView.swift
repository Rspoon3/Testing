//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    @AppStorage("Integer") private var integer: Int = 0
    @AppStorage("Decimal") private var decimal: Double = 0
    @AppStorage("Text") private var text: String = "abc"
    @AppStorage("Data") private var data: Data = Data()
    @AppStorage("Date") private var date: Date = Date()

    var body: some View {
        VStack {
            VStack(spacing: 30) {
                Button("Integer \(integer)") {
                    integer = Int.random(in: 1...100)
                }
                Button("Decimal \(decimal)") {
                    decimal = Double.random(in: 1...100)
                }
                Button("Text \(text)") {
                    text = "abc\(Int.random(in: 1...100))"
                }
                Button("Data \(data.count)") {
                    data = String("\(Int.random(in: 1...100))").data(using: .utf8)!
                }
                Button("Date \(date.formatted())") {
                    date = .init(timeIntervalSince1970: TimeInterval(Int.random(in: 1...10000)))
                }
            }
            
            Divider()
            
            UserDefaultsView()
        }
        .padding()
    }
}


#Preview {
    ContentView()
}
