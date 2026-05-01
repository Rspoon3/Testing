//
//  FakeNetworkService.swift
//  TestDrive
//
//  Created by Claude on 8/28/25.
//

import Foundation

actor FakeNetworkService {
    static let shared = FakeNetworkService()
    
    private init() {}
    
    func fetchRandomValue() async -> NetworkResponse {
        print("🌐 Starting network call...")
        
        await sleep()
        let randomValue = Int.random(in: 0...10)
        let response = NetworkResponse(value: randomValue)
        
        print("🌐 Network call completed: \(randomValue)")
        return response
    }
    
    func sleep() async {
        try? await Task.sleep(for: .seconds(2))
    }
}

struct NetworkResponse {
    let value: Int
    let timestamp = Date()
}
