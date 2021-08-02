//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    @StateObject var manager = HealthKitManager()
    
    var body: some View {
        NavigationView{
            ZStack{
                Color(.systemGroupedBackground)
                    .edgesIgnoringSafeArea(.all)
                switch manager.state{
                case .loading:
                    ProgressView()
                        .task{
                            await manager.loadData(authorize: true)
                        }
                case .failed(let error):
                    VStack{
                        Text("Error")
                            .font(.title)
                            .fontWeight(.medium)
                            .padding(.bottom, 6)
                        Text(error.localizedDescription)
                            .foregroundColor(.secondary)
                            .padding(.bottom)
                        Image(systemName: "exclamationmark.triangle")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 70)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(10)
                case .loaded:
                    StepsListView(manager: manager)
                        .refreshable{
                            await manager.loadData(authorize: false)
                        }
                }
            }
            .navigationTitle("Steps")
        }
        .navigationViewStyle(.stack)
    }
}


struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
