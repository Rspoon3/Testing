//
//  MemoryColorsTitleView.swift
//  Testing
//
//  Created by Ricky on 11/4/24.
//

import SwiftUI
struct MemoryColorsTitleView: View {
    @State private var flippedLettersMemory = Array(repeating: false, count: "MEMORY".count)
    @State private var flippedLettersPictures = Array(repeating: false, count: "PICTURES".count)
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 2) {
                ForEach(Array("MEMORY".enumerated()), id: \.offset) { index, letter in
                    createLetter(
                        title: flippedLettersMemory[index] ? "" : String(letter),
                        value: flippedLettersMemory[index]
                    )
                    .onTapGesture {
                        flippedLettersMemory[index].toggle()
                    }
                }
            }
            
            HStack(spacing: 2) {
                ForEach(Array("PICTURES".enumerated()), id: \.offset) { index, letter in
                    createLetter(
                        title: flippedLettersPictures[index] ? "" : String(letter),
                        value: flippedLettersPictures[index]
                    )
                    .onTapGesture {
                        flippedLettersPictures[index].toggle()
                    }
                }
            }
        }
        .task {
            await startFlipping()
        }
    }
    
    private func createLetter(title: String, value: Bool) -> some View {
        Text(value ? "" : title) // Empty text when flipped
            .font(.title)
            .frame(width: 40, height: 40)
            .background(Color.pink)
            .foregroundColor(.white)
            .cornerRadius(4)
            .rotation3DEffect(
                .degrees(value ? 180 : 0.001),
                axis: (x: 0, y: 1, z: 0)
            )
            .animation(.easeInOut(duration: 0.6), value: value)
    }
    
    private func startFlipping() async {
        while true {
            await withTaskGroup(of: Void.self) { group in
                let lettersToFlip = Int.random(in: 1...4)
                for _ in 0..<lettersToFlip {
                    group.addTask { await flipRandomLetter() }
                }
            }
        }
    }
    
    private func flipRandomLetter() async {
        let index = Int.random(in: 0...13)
        let delay = Double.random(in: 2...5)
        let memoryCount = "MEMORY".count
        
        // Delay before flipping
        try? await Task.sleep(for: .seconds(delay))
        
        // Flip the letter
        if index >= memoryCount {
            let pictureIndex = index - memoryCount
            flippedLettersPictures[pictureIndex].toggle()
        } else {
            flippedLettersMemory[index].toggle()
        }
        
        // Delay before flipping back
        let backDelay = Double.random(in: 2...5)
        try? await Task.sleep(for: .seconds(backDelay))
        
        // Flip back the letter
        if index >= memoryCount {
            let pictureIndex = index - memoryCount
            flippedLettersPictures[pictureIndex].toggle()
        } else {
            flippedLettersMemory[index].toggle()
        }
    }
}

#Preview {
    MemoryColorsTitleView()
}
