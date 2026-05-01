//
//  Peripheral.swift
//  Testing
//
//  Created by Ricky on 12/16/24.
//

import Foundation

struct Peripheral: Identifiable {
    let id = UUID()
    let name: String
    let rssi: Int
    let isConnectable: Bool
    let advertisementData: [String: Any]
}
