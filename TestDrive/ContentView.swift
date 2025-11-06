//
//  ContentView.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 10/26/25.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "star")
                .font(.system(size: 40))
                .foregroundStyle(.white)

            Text("This is a star")
                .font(.headline)
                .foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 140)
        .padding()
        .glassEffect(
            .clear.tint(.green).interactive(),
            in: .rect(cornerRadius: 16)
        )
    }
}

#Preview {
    ContentView()
}
