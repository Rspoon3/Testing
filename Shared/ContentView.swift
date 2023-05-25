//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        Form {
            ForEach(Item.previewData.sortedByKeyPath()) { item in
                Section {
                    LabeledContent("Id", value: item.id.formatted())
                    LabeledContent("Rank", value: item.rank?.formatted() ?? "NA")
                    LabeledContent("Start Date", value: item.startDate?.description ?? "NA")
                    LabeledContent("Points Earned", value: item.pointsEarned.formatted())
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
