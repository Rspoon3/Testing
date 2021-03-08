//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var socketManager: SocketIOManager
    @State private var distance = "N/A"
    @State private var time = "N/A"
    @State private var follow = true
    let isDriver = true
    
    var body: some View {
        Group{
            if isDriver{
                ZStack(alignment: .topLeading){
                    DriverMap()
                    VStack(alignment: .leading){
                        Text("Driver")
                        Text("Socket Connected: ") + Text(socketManager.isConnected.description)
                            .foregroundColor(socketManager.isConnected ? .green : .red)
                        
                        Button("Send fake data"){
                            let lat = Double.random(in: 41...41.2)
                            let long = Double.random(in: 70...70.3)
                            socketManager.sendLocation(lat: lat, long: -long)
                        }
                    }
                    .padding(.top, 50)
                    .padding(.horizontal)
                    .font(.title)
                }
            } else{
                ZStack(alignment: .topLeading){
                    RiderMap(distanceRemaining: $distance, timeRemaining: $time, followCamera: $follow)
                    
                    VStack(alignment: .leading){
                        Text("Rider")
                        Text("Socket Connected: ") + Text(socketManager.isConnected.description)
                            .foregroundColor(socketManager.isConnected ? .green : .red)
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


