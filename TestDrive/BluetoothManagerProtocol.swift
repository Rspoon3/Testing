//
//  BluetoothManagerProtocol.swift
//  Testing
//
//  Created by Ricky on 12/20/24.
//

import Foundation

protocol BluetoothManagerProtocol: AnyObject {
    var delegate: BluetoothManagerDelegate? { get set }
    
    func startScanning()
    func stopScanning()
}

extension BluetoothManager: BluetoothManagerProtocol {}
