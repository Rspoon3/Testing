//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI
import SwiftData
import LoremSwiftum

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query var items: [Item]
    @Query var massUnits: [MassUnit]

    var body: some View {
        NavigationStack {
            List(items) { item in
                LabeledContent {
                    Text(item.massUnit.measurement.formatted())
                } label: {
                    Text(item.title)
                }
            }
            .navigationTitle(massUnits.count.formatted())
            .toolbar {
                ToolbarItem {
                    Button("Add Item") {
//                        let massUnit = MassUnit(weight: Double.random(in: 1...100), unit: Bool.random() ? .kilograms : .pounds)
                        
                        let massUnit = MassUnit(weight: 50, unit: .kilograms)
                        let item = Item(title: Lorem.title, massUnit: massUnit)
                        modelContext.insert(item)
                    }
                }
                ToolbarItem(placement: .destructiveAction) {
                    Button("Delete") {
                        for item in items {
                            modelContext.delete(item)
                        }
                    }
                }
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
