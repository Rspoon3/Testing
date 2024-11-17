//
//  SwipeView.swift
//  Testing
//
//  Created by Ricky on 11/17/24.
//

import SwiftUI

struct SwipeView: View {
    
    @AppStorage("score") private var score: Double = 0
    @AppStorage("totalSwipes") private var totalSwipes = 0
    @AppStorage("correctSwipes") private var correctSwipes = 0
    @AppStorage("currentIndex") private var currentIndex = 1
    @AppStorage("nextNumber") private var nextNumber = 4
    
    @State private var indicatorState: IndicatorState = .idle
    
    @State private var idleTask: Task<Void, Never>?
    
    
    
    
    init() {
        // Initialize the cards array based on saved currentIndex and nextNumber
        let currentIndex = UserDefaults.standard.integer(forKey: "currentIndex")
        let nextNumber = UserDefaults.standard.integer(forKey: "nextNumber") > 0 ? UserDefaults.standard.integer(forKey: "nextNumber") : 4
        _cards = State(initialValue: (0..<3).map { i in
            Card(id: currentIndex + i + 1)
        })
    }
    
    enum IndicatorState {
        case idle
        case swiping
        case correct
        case incorrect
    }
    
    private var correctPercentage: Double {
        guard totalSwipes > 0 else { return 0.0 }
        return (Double(correctSwipes) / Double(totalSwipes))
    }
    
    private var indicatorSymbol: String {
        switch indicatorState {
        case .idle, .swiping: return ""
        case .correct: return "checkmark"
        case .incorrect: return "xmark"
        }
    }
    
    private var indicatorColor: Color {
        switch indicatorState {
        case .idle, .swiping: return .clear
        case .correct: return .green
        case .incorrect: return .red
        }
    }
    
    @State private var cards: [Card]
    
    
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
    
    /// Low  k  (e.g., 50–100): Makes swipe count influence weaker, so accuracy dominates. Good if you want players with fewer swipes but high accuracy to rank well.
    /// Medium  k  (e.g., 200–500): Offers a balance, letting both accuracy and swipe count impact the score.
    /// High  k  (e.g., 1000+): Strongly favors experience, making it easier for players with high swipe counts to rank well, even with moderate accuracy.
    private func updateScore() {
        let k = 200.0
        score = correctPercentage * (1 - exp(-Double(totalSwipes) / k))
    }
    
    private func updateCard(card: Card, with translation: CGSize) {
        if let index = cards.firstIndex(where: { $0.number == card.number }) {
            // Allow x offset to be the full horizontal translation
            // Clamp y offset to be within -150 and 150
            let clampedY = min(max(translation.height, -150), 150)
            cards[index].offset = CGSize(width: translation.width, height: clampedY)
        }
        
        withAnimation {
            indicatorState = .swiping
        }
    }
    
    private func endSwipe(card: Card) {
        if abs(card.offset.width) > 150 {
            // Determine swipe direction
            let swipedRight = card.offset.width > 0
            
            // Check if the swipe direction matches the primality of the number
            let isCorrect = (swipedRight && card.isPrime) || (!swipedRight && !card.isPrime)
            totalSwipes += 1
            
            if isCorrect {
                correctSwipes += 1
                //                withAnimation(.linear(duration: 1)) {
                indicatorState = .correct
                //                }
            } else {
                //                withAnimation(.linear(duration: 1)) {
                indicatorState = .incorrect
                //                }
            }
            
            
            updateScore()
            
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
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if indicatorState != .swiping {
                    withAnimation {
                        indicatorState = .idle
                    }
                }
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
    
    
    var body: some View {
        VStack {
            Text(correctPercentage.formatted(.percent.precision(.fractionLength(1))))
                .contentTransition(.numericText(value: correctPercentage))
                .font(.system(size: 60, weight: .bold, design: .rounded))
                .animation(.default, value: correctPercentage)
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.teal, Color.blue, Color.purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            Image(systemName: indicatorSymbol)
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .foregroundStyle(indicatorColor)
                .contentTransition(.symbolEffect(.replace))
                .transition(.opacity)
                .fontWeight(.bold)
            
            //                        Text(score.formatted(.percent.precision(.fractionLength(0...2))))
            //                            .contentTransition(.numericText(value: score))
            
            ZStack {
                ForEach(cards.reversed()) { card in
                    let isTopCard = card.number == cards.first?.number
                    CardView(card: card, width: UIScreen.main.bounds.width - 40)
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
                        .animation(.spring(), value: card.offset)
                    //                        .opacity(opacity(value: card.number))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                }
            }
        }
    }
}
