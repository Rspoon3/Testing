//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

import SwiftUI

struct ContentView: View {
//    @State private var cards: [Card] = [
//        Card(id: 1, number: 1),
//        Card(id: 2, number: 2),
//        Card(id: 3, number: 3),
//    ]

    @AppStorage("totalSwipes") private var totalSwipes = 0
    @AppStorage("correctSwipes") private var correctSwipes = 0
    @AppStorage("currentIndex") private var currentIndex = 1
    @AppStorage("nextNumber") private var nextNumber = 4
    
    private var correctPercentage: Double {
         guard totalSwipes > 0 else { return 0.0 }
         return (Double(correctSwipes) / Double(totalSwipes))
     }
    
    @State private var cards: [Card]

        init() {
            // Initialize the cards array based on saved currentIndex and nextNumber
            let currentIndex = UserDefaults.standard.integer(forKey: "currentIndex")
            let nextNumber = UserDefaults.standard.integer(forKey: "nextNumber") > 0 ? UserDefaults.standard.integer(forKey: "nextNumber") : 4
            _cards = State(initialValue: (0..<3).map { i in
                Card(id: currentIndex + i + 1)
            })
            
            print(cards.map(\.number))
        }

    var body: some View {
        ZStack {
            GeometryReader { geo in
                MovingNumbersBackground()
                
                VStack {
                    Text(correctPercentage.formatted(.percent))
                    
                    ZStack {
                        ForEach(cards.reversed()) { card in
                            let isTopCard = card.number == cards.first?.number
                            CardView(card: card, width: geo.size.width - 40)
                                .offset(x: card.offset.width, y: card.offset.height)
                                .rotationEffect(.degrees(Double(card.offset.width / 30)))
                                .gesture(
                                    DragGesture()
                                        .onChanged { gesture in
                                            updateCard(card: card, with: gesture.translation)
                                        }
                                        .onEnded { _ in
                                            endSwipe(card: card)
                                        }
                                )
                                .opacity(isTopCard ? 1 : calculateOpacity(for: cards.first?.offset ?? .zero))
                                .animation(.spring())
                            //                        .opacity(opacity(value: card.number))
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        }
                    }
                }
            }
        }
    }
    
    func opacity(value: Int) -> Double {
        if currentIndex == value {
            return 1
        } else if currentIndex + 1 == value {
            return 0.5
        } else {
            return 0
        }
    }
    
    private func calculateOpacity(for offset: CGSize) -> Double {
        // Calculate distance from the center
        let maxDistance: CGFloat = 300 // Adjust this based on desired opacity range
        let distance = min(maxDistance, sqrt(offset.width * offset.width + offset.height * offset.height))
        
        // Interpolate opacity from 0.25 to 1 based on distance from the center
        return 0.25 + Double(distance / maxDistance) * 0.75
    }
    
//    private func calculateOpacity(for offset: CGSize) -> Double {
//         // Calculate distance from the center
//         let maxDistance: CGFloat = 300 // Adjust this based on desired opacity range
//         let distance = sqrt(offset.width * offset.width + offset.height * offset.height)
//         
//         // Scale the opacity based on distance, with max opacity at the center and decreasing
//         return 1 - max(0.1, Double(1 - distance / maxDistance))
//     }

//    private func updateCard(card: Card, with translation: CGSize) {
//        if let index = cards.firstIndex(where: { $0.number == card.number }) {
//            cards[index].offset = translation
//        }
//    }
    
    private func updateCard(card: Card, with translation: CGSize) {
        if let index = cards.firstIndex(where: { $0.number == card.number }) {
            // Allow x offset to be the full horizontal translation
            // Clamp y offset to be within -150 and 150
            let clampedY = min(max(translation.height, -150), 150)
            cards[index].offset = CGSize(width: translation.width, height: clampedY)
        }
    }
    
    private func endSwipe(card: Card) {
        if abs(card.offset.width) > 150 {
            // Determine swipe direction
            let swipedRight = card.offset.width > 0
            
            // Check if the swipe direction matches the primality of the number
            let isCorrect = (swipedRight && card.isPrime) || (!swipedRight && !card.isPrime)
            totalSwipes += 1
            if isCorrect { correctSwipes += 1 }
            
            
            // Move the card off-screen first
            withAnimation(.linear(duration: 0.4)) {
                let direction: CGFloat = card.offset.width > 0 ? 1 : -1
                if let index = cards.firstIndex(where: { $0.number == card.number }) {
                    cards[index].offset.width += direction * 500 // Move it far off-screen
                }
            }
            
            // Delay the removal and addition of a new card to allow the animation to complete
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                removeAndAddNewCard(card)
            }
        } else {
            resetCard(card)
        }
    }

    private func removeAndAddNewCard(_ card: Card) {
        // Remove the swiped card
        cards.removeAll { $0.number == card.number }
        
        // Add a new card with the next number
        cards.append(Card(id: nextNumber))
        nextNumber += 1
        
        currentIndex += 1
    }

    private func resetCard(_ card: Card) {
        if let index = cards.firstIndex(where: { $0.number == card.number }) {
            cards[index].offset = .zero
        }
    }
}

struct CardView: View {
    var card: Card
    let width: CGFloat
    
    var body: some View {
        Image("numbers\(card.imageNumber)")
            .resizable()
            .scaledToFill()
            .frame(width: width, height: width * 1.5)
//            .aspectRatio(3/4, contentMode: .fill)
//            .aspectRatio(2 / 3, contentMode: .fit)
//
//            .containerRelativeFrame(.horizontal){ width, _ in width - 20 * 2 }

//            .aspectRatio(0.5, contentMode: .fill)
            .blur(radius: 2)
            .overlay {
                ZStack {
                    Color.black.opacity(0.75)
                    Text("\(card.number)")
                        .font(.system(size: 160, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(radius: 5)
                }
            }
            .cornerRadius(20)
    }
}

struct Card: Identifiable {
    let id = UUID()
    let number: Int
    var offset: CGSize = .zero
    let imageNumber: Int
    let isPrime: Bool
    
    init(id: Int) {
        self.number = id
        imageNumber = (id % 19) + 1
        
        
        guard id > 1 else {
            isPrime = false
            return
        }
        
        var temp = true
        for i in 2..<Int(sqrt(Double(id))) + 1 {
            if id % i == 0 { temp = false }
        }
        
        isPrime = temp
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}


private func isPrime(_ n: Int) -> Bool {
    guard n > 1 else { return false }
    for i in 2..<Int(sqrt(Double(n))) + 1 {
        if n % i == 0 { return false }
    }
    return true
}
