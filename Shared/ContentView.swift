//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

import SwiftUI

struct ContentView: View {
    @State private var cards: [Card] = [
        Card(id: 1, number: 1),
        Card(id: 2, number: 2),
        Card(id: 3, number: 3),
    ]
    
    @State private var currentIndex = 1
    @State private var nextNumber = 4  // Keeps track of the next number to display
    
    var body: some View {
        ZStack {
            GeometryReader { geo in
                MovingNumbersBackground()
                
                ForEach(cards.reversed()) { card in
                    CardView(card: card, width: geo.size.width - 40)
                        .offset(x: card.offset.width, y: card.offset.height)
                        .rotationEffect(.degrees(Double(card.offset.width / 20)))
                        .gesture(
                            DragGesture()
                                .onChanged { gesture in
                                    updateCard(card: card, with: gesture.translation)
                                }
                                .onEnded { _ in
                                    endSwipe(card: card)
                                }
                        )
                        .animation(.spring())
                        .opacity(opacity(value: card.id))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
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

    private func updateCard(card: Card, with translation: CGSize) {
        if let index = cards.firstIndex(where: { $0.id == card.id }) {
            cards[index].offset = translation
        }
    }

    private func endSwipe(card: Card) {
        if abs(card.offset.width) > 150 {
            withAnimation {
                removeAndAddNewCard(card)
            }
        } else {
            resetCard(card)
        }
    }

    private func removeAndAddNewCard(_ card: Card) {
        // Remove the swiped card
        cards.removeAll { $0.id == card.id }
        
        // Add a new card with the next number
        cards.append(Card(id: nextNumber, number: nextNumber))
        nextNumber += 1
        
        currentIndex += 1
    }

    private func resetCard(_ card: Card) {
        if let index = cards.firstIndex(where: { $0.id == card.id }) {
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
    let id: Int
    let number: Int
    var offset: CGSize = .zero
    let imageNumber: Int
    let isPrime: Bool
    
    init(id: Int, number: Int) {
        self.id = id
        self.number = number
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
