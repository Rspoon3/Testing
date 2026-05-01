//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI
import SwiftCSV

struct ContentView: View {
    @State var dictionary: [Int: Int] = [:]
    let minimumiOSVersion = 15
    
    var body: some View {
        Text("Hello, world!")
            .padding()
            .onAppear {
                test()
            }
    }
    
    func test() {
        do {
            let csv = try EnumeratedCSV(name: "versions", extension: "csv", bundle: .main)!
            let allColumns = csv.columns!
            let iOSColumns = allColumns.filter {$0.header.contains("iOS")}
            
            for column in iOSColumns {
                let iOSVersionString = column.header.components(separatedBy: CharacterSet.decimalDigits.inverted).filter{!$0.isEmpty}.joined(separator: ".")
                let iOSVersion = Double(iOSVersionString)!
                let majorVersion = Int(iOSVersion)
                
                print(column.header, iOSVersion, majorVersion)
                
                if majorVersion < minimumiOSVersion { continue }
                
                
                for row in column.rows.suffix(1) {
                    let rowValue = Int(Double(row) ?? 0)
                    let existingValue = dictionary[majorVersion] ?? 0
                    let newValue = rowValue + existingValue
                    
                    if iOSVersion == 17.2 {
                        print(newValue)
                    }
                    dictionary.updateValue(newValue, forKey: majorVersion)
                }
            }
            
            print(dictionary)
            
            let total = dictionary.map(\.value).reduce(0, +)
            
            for (key, value) in dictionary {
                let percent = Double(value) / Double(total)
                print(key, percent.formatted(.percent))
            }
        } catch {
            print("Error")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
