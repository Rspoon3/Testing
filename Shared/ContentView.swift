//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//


import SwiftUI
import Combine

struct Item: Identifiable, Equatable{
    let id = UUID()
    let value: Int
    var isPinned = false
}

struct ContentView: View {
    @State var items = Array(0...12).map({Item(value: $0)})
    @Namespace private var animation
    let timer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()

    
    var body: some View {
        ScrollView{
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
            ], spacing: 20){
                Section{
                    ForEach(items.filter{$0.isPinned}){ item in
                        Circle()
                            .frame(height: 100)
                            .overlay(Text(item.value.description).foregroundColor(.white))
                            .onTapGesture{
                                toggle(item)
                            }
                            .matchedGeometryEffect(id: item.id, in: animation)
                    }
                }
            }.animation(.default)
            
            LazyVStack{
                ForEach(items.filter{!$0.isPinned}){ item in
                    Color.blue
                        .clipShape(Circle())
                        .frame(height: 100)
                        .overlay(Text(item.value.description).foregroundColor(.white))
                        .onTapGesture{
                            toggle(item)
                        }
                        .matchedGeometryEffect(id: item.id, in: animation)
                    
                }
            }
            .animation(.default)
            .onReceive(timer) {_ in
                toggle(items.randomElement()!)
            }
        }
    }
    
    private func toggle(_ item: Item){
        if let index = items.firstIndex(where: {$0 == item}){
            items[index].isPinned.toggle()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

