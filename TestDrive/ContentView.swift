//
//  ContentView.swift
//  TestDrive
//
//  Created by Ricky Witherspoon on 10/26/25.
//

import SwiftUI

struct ContentView: View {
    // MARK: - Body

    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Image(systemName: "globe")
                    .imageScale(.large)
                    .foregroundStyle(.tint)

                Text("Haptic Button Examples")
                    .font(.title2)
                    .fontWeight(.bold)

                buttonStyleExamples
            }
            .padding()
        }
    }

    // MARK: - Private Views

    private var buttonStyleExamples: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Using .hapticButtonStyle()")
                .font(.headline)

            VStack(spacing: 12) {
                Button("Regular Button") {
                    print("Regular button")
                }

                Button("Impact (default)") {
                    print("Impact")
                }
                .hapticButtonStyle()

                Button("Selection") {
                    print("Selection")
                }
                .hapticButtonStyle(.selection)

                Button("Success") {
                    print("Success")
                }
                .hapticButtonStyle(.success)

                Button("Warning") {
                    print("Warning")
                }
                .hapticButtonStyle(.warning)

                Button("Delete", role: .destructive) {
                    print("Delete")
                }
                .hapticButtonStyle(.error)

                Button {
                    print("Custom label")
                } label: {
                    HStack {
                        Image(systemName: "star.fill")
                        Text("Custom Label")
                    }
                }
                .hapticButtonStyle(.impact)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ContentView()
}
