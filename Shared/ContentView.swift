//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    @State private var distance = "N/A"
    @State private var time = "N/A"
    @State private var follow = true
    let isDriver = false
    
    var body: some View {
        Group{
            if isDriver{
                ZStack(alignment: .topLeading){
                    DriverMap()
                    Text("Driver")
                        .padding(.top, 50)
                        .padding(.horizontal)
                        .font(.title)
                }
            } else{
                ZStack(alignment: .topLeading){
                    RiderMap(distanceRemaining: $distance, timeRemaining: $time, followCamera: $follow)
                    
                    VStack(alignment: .leading){
                        Text("Rider")
                        Text(distance)
                        Text(time)
                        Toggle("Follow Camera", isOn: $follow)
                    }
                    .padding(.top, 50)
                    .padding(.horizontal)
                    .font(.title)
                }
            }
        }
        .edgesIgnoringSafeArea(.all)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


