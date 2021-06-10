//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View{
    @State private var tabSelection = Tab.navigationBarItemTest

    
    enum Tab {
        case navigationBarItemTest
        case navigationBarMenuTest
        case toolbarItemTest
        case ToolbarItemMenuTest
    }

    
    var body: some View{
        TabView(selection: $tabSelection) {
            NavigationBarItemTest()
                .tabItem {
                    Label("Nav Bar", systemImage: "1.circle")
                }
                .tag(Tab.navigationBarItemTest)
            
            NavigationBarMenuTest()
                .tabItem {
                    Label("Nav Bar Menu", systemImage: "2.circle")
                }
                .tag(Tab.navigationBarMenuTest)
            
            ToolbarItemTest()
                .tabItem {
                    Label("Toolbar Bar", systemImage: "3.circle")
                }
                .tag(Tab.toolbarItemTest)
            
            ToolbarItemMenuTest()
                .tabItem {
                    Label("Toolbar Bar Menu", systemImage: "4.circle")
                }
                .tag(Tab.ToolbarItemMenuTest)
        }
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


struct NavigationBarItemTest: View{
    @State private var show1 = false
    
    var body: some View{
        NavigationView{
            Color.blue
                .frame(width: 200, height: 200)
                .cornerRadius(10)
                .navigationBarTitle("1")
                .frame(width: 200, height: 200)
                .cornerRadius(10)
                .sheet(isPresented: $show1, content: {
                    Color.blue
                })
                .navigationBarItems(trailing:
                                        Button("Show"){
                                            show1.toggle()
                                        }.keyboardShortcut("1", modifiers: .command)
                )
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct NavigationBarMenuTest: View{
    @State private var show2 = false
    
    var body: some View{
        NavigationView{
            Color.red
                .frame(width: 200, height: 200)
                .cornerRadius(10)
                .navigationBarTitle("2")
                .frame(width: 200, height: 200)
                .cornerRadius(10)
                .sheet(isPresented: $show2, content: {
                    Color.red
                })
                .navigationBarItems(trailing:
                                        Menu{
                                            Button("Show"){
                                                show2.toggle()
                                            }.keyboardShortcut("2", modifiers: .command)
                                        } label: {
                                            Image(systemName: "plus")
                                        }
                )
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}



struct ToolbarItemTest: View{
    @State private var show3 = false
    
    var body: some View{
        NavigationView{
            Color.green
                .frame(width: 200, height: 200)
                .cornerRadius(10)
                .navigationBarTitle("3")
                .frame(width: 200, height: 200)
                .cornerRadius(10)
                .sheet(isPresented: $show3, content: {
                    Color.green
                })
                .toolbar{
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Show"){
                            show3.toggle()
                        }.keyboardShortcut("3", modifiers: .command)
                    }
                }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

struct ToolbarItemMenuTest: View{
    @State private var show4 = false

    var body: some View{
        NavigationView{
            Color.yellow
                .frame(width: 200, height: 200)
                .cornerRadius(10)
                .navigationBarTitle("4")
                .frame(width: 200, height: 200)
                .cornerRadius(10)
                .sheet(isPresented: $show4, content: {
                    Color.yellow
                })
                .toolbar{
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu{
                            Button("Show"){
                                show4.toggle()
                            }.keyboardShortcut("4", modifiers: .command)
                        } label: {
                            Image(systemName: "plus")
                        }
                    }
                }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
