//
//  SocketIOManager.swift
//  Testing
//
//  Created by Richard Witherspoon on 2/3/21.
//

import SwiftUI
import SocketIO
import AVFoundation

class SocketIOManager: ObservableObject {
    static let shared = SocketIOManager()
    private let manager: SocketManager
    private let socket: SocketIOClient
    @Published var isConnected = false
    
    
    private init() {
        let config: SocketIOClientConfiguration = [.log(false), .compress]
        let url = URL(string: "https://ezmr-tracking-map.herokuapp.com")!
        
        manager = SocketManager(socketURL: url, config: config)
        socket = manager.defaultSocket
        
        establishConnection()
    }
    
    
    private func establishConnection() {
        socket.on(clientEvent: .connect) {data, ack in
            print("socket connected")
            self.isConnected = true
            AudioServicesPlayAlertSound(SystemSoundID(1016))
        }
        
        socket.on(clientEvent: .error) {data, ack in
            print("socket error")
            self.isConnected = false
        }
        
        socket.connect()
    }
    
    func closeConnection() {
        
        socket.on(clientEvent: .disconnect){_,_ in
            AudioServicesPlayAlertSound(SystemSoundID(1322))
        }
        
        socket.disconnect()
    }
    
    func sendLocation(lat: Double, long: Double) {
        print("Sending...", lat, long)
        socket.emit("locationUpdate", lat, long)
    }
    
    func getLocation(completionHandler: @escaping (_ location: Location?) -> Void) {
        socket.on("locationUpdate") { (dataArray, socketAck) -> Void in
            guard
                let dict = dataArray[0] as? [String: Any],
                let data = try? JSONSerialization.data(withJSONObject: dict),
                let location = try? JSONDecoder().decode(Location.self, from: data)
            else {
                completionHandler(nil)
                return
            }
            
            completionHandler(location)
        }
    }
}


struct Location: Codable{
    var lat: Double
    var long: Double
}
