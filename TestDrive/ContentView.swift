//
//  ContentView.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 10/26/25.
//

import SwiftUI

struct ContentView: View {
    @State private var demoOutput = "Running envelope encryption demo..."

    var body: some View {
        VStack {
            Text("SQLiteData Envelope Encryption")
                .font(.headline)
            Text(demoOutput)
                .font(.footnote.monospaced())
                .multilineTextAlignment(.center)
        }
        .padding()
        .task {
            do {
                let output = try EnvelopeEncryptionDemo.run()
                demoOutput = "Decrypted secret: \(output)"
            } catch {
                demoOutput = "Demo failed: \(error)"
            }
        }
    }
}

#Preview {
    ContentView()
}
