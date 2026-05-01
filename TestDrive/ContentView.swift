//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI
import IOKit
import IOKit.ps

class PowerMonitor: ObservableObject {
    @Published var wattage: Int = 0
    private var powerSourceRunLoopSource: CFRunLoopSource?
    
    init() {
        startMonitoring()
    }
    
    private func startMonitoring() {
        guard
            let source = IOPSNotificationCreateRunLoopSource({ context in
                guard let context = context else { return }
                let monitor = Unmanaged<PowerMonitor>.fromOpaque(context).takeUnretainedValue()
                monitor.updateWattage()
            }, Unmanaged.passUnretained(self).toOpaque())?.takeRetainedValue()
        else {
            return
        }
        
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .defaultMode)
        updateWattage()
    }
    
    private func updateWattage() {
        DispatchQueue.global(qos: .background).async {
            let newWattage = self.getChargingWattage()
            DispatchQueue.main.async {
                self.wattage = newWattage
            }
        }
    }
    
    private func getChargingWattage() -> Int {
        let service = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSmartBattery"))
        var properties: Unmanaged<CFMutableDictionary>?

        defer { IOObjectRelease(service) }
        
        guard
            service != 0,
            IORegistryEntryCreateCFProperties(service, &properties, kCFAllocatorDefault, 0) == KERN_SUCCESS,
            let dict = properties?.takeRetainedValue() as? [String: Any],
            let adapterDetails = dict["AppleRawAdapterDetails"] as? [[String: Any]],
            let firstAdapter = adapterDetails.first,
            let chargerWattage = firstAdapter["Watts"] as? Int else {
            return 0
        }
        
        return chargerWattage
    }
}

struct ContentView: View {
    @StateObject private var powerMonitor = PowerMonitor()
    
    var body: some View {
        VStack {
            Text("Charging Wattage")
                .font(.largeTitle)
                .padding()
            
            Text("\(powerMonitor.wattage) W")
                .font(.title)
                .bold()
                .padding()
        }
        .frame(width: 250, height: 150)
    }
}
