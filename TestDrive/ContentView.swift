//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        UserDefaultsDebugView()
            .onAppear {
                UserDefaults.standard.set(true, forKey: "testBool")
                UserDefaults.standard.set(false, forKey: "testBool-false")
                //                UserDefaults.standard.set(123, forKey: "TestValue")
                //                UserDefaults.standard.set(456.789, forKey: "testDouble")
                //                UserDefaults.standard.set("Ricky", forKey: "testString")
                //                UserDefaults.standard.set(Date.now, forKey: "testDate")
                //                UserDefaults.standard.set("okay", forKey: "testOKAY")
//                UserDefaults.standard.set([
//                    "one",
//                    "two",
//                    3,
//                    4.56,
//                    8,
//                    true,
//                    true,
//                    Date.now,
//                    false
//                ], forKey: "testArrray")
            }
    }
}

#Preview {
    ContentView()
}
