//
//  GameView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct GameView: View {
    @State private var viewModel = GameViewModel()
    
    var body: some View {
        @Bindable var viewModel = viewModel
        
        VStack {
            Text("Round \(viewModel.round.formatted())")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .contentTransition(.numericText(value: Double(viewModel.round)))
            
            PlayerSegmentedPicker(selectedPlayer: viewModel.currentPlayer)
            
            VStack(spacing: 20) {
                HStack(spacing: 20) {
                    ForEach(0..<2) { index in
                        FlashableColorView(
                            colorType: viewModel.colors[index],
                            opacity: viewModel.currentPlayer == .user ? 1 : 0.7,
                            showBorder: $viewModel.showBorders[index]
                        )
                        .onTapGesture {
                            if viewModel.canTap {
                                Task {
                                    await viewModel.handleUserTap(color: viewModel.colors[index])
                                }
                            }
                        }
                    }
                }
                
                HStack(spacing: 20) {
                    ForEach(2..<4) { index in
                        FlashableColorView(
                            colorType: viewModel.colors[index],
                            opacity: viewModel.currentPlayer == .user ? 1 : 0.7,
                            showBorder: $viewModel.showBorders[index]
                        )
                        .onTapGesture {
                            if viewModel.canTap {
                                Task {
                                    await viewModel.handleUserTap(color: viewModel.colors[index])
                                }
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding([.top, .horizontal])
        }
        .background(
            Image("clouds")
                .resizable()
                .ignoresSafeArea()
                .overlay(Color.black.opacity(0.75))
        )
        .overlay {
            if viewModel.gameEnded {
                Color.black.opacity(0.75)
                    .transition(.opacity)
            }
        }
        .task {
            await viewModel.startGame()
        }
    }
}


#Preview {
    GameView()
}
