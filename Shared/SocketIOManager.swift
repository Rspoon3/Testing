//
//  SocketIOManager.swift
//  Testing
//
//  Created by Richard Witherspoon on 2/3/21.
//

import SwiftUI
import SocketIO

class SocketIOManager: ObservableObject {
    static let shared = SocketIOManager()
    
    
    private let manager: SocketManager
    private let socket: SocketIOClient
    
    
    private init() {
        let config: SocketIOClientConfiguration = [.log(false), .compress]
        let url = URL(string: "http://localhost:3000")!
        
        manager = SocketManager(socketURL: url, config: config)
        socket = manager.defaultSocket
    }
    
    
    func establishConnection() {
        socket.on(clientEvent: .connect) {data, ack in
            print("socket connected")
        }
        
        socket.on(clientEvent: .error) {data, ack in
            print("socket error")
        }
        
        socket.connect()
    }
    
    func closeConnection() {
        socket.disconnect()
    }
    
    func sendLocation(lat: Double, long: Double) {
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
