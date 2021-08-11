//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    @StateObject var model = ContentViewModel()
    
    var body: some View {
        NavigationView{
            List{
                ForEach(model.data){ data in
                    Section{
                        Text(data.urlString)
                        Text(data.dataInfo)
                        Text("Status Code: \(data.statusCode)")
                            .foregroundColor(data.statusCode == 200 ? .green : .red)
                    }
                }
            }
            .navigationTitle(model.title)
            .listStyle(InsetGroupedListStyle())
            .toolbar {
                ToolbarItemGroup {
                    Button {
                        model.data.removeAll(keepingCapacity: true)
                        model.startLoading()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    
                    Toggle(isOn: $model.firstFour) {
                        Text("First Four")
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
