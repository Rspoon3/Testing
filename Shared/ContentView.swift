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
                    LabeledContent("favoriteRank", value: item.favoriteRank?.formatted() ?? "NA")
                    LabeledContent("recommended", value: item.isRecommended.description)
                    LabeledContent("popularityRank", value: item.popularityRank.formatted())
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
