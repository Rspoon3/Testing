//
//  GameView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct GameView: View {
    @State private var viewModel = GameViewModel()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        @Bindable var viewModel = viewModel
        
        VStack {
            Text("Round \(viewModel.round.formatted())")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .contentTransition(.numericText(value: Double(viewModel.round)))
                .animation(.default, value: viewModel.round)
            
            PlayerSegmentedPicker(selectedPlayer: viewModel.currentPlayer)
            
            VStack(spacing: 20) {
                HStack(spacing: 20) {
                    ForEach(0..<2) { index in
                        FlashableImage(
                            index: index,
                            opacity: viewModel.currentPlayer == .user ? 1 : 0.7,
                            showBorder: viewModel.selectedIndex == index
                        )
                        .overlay(Text(index.formatted()).font(.largeTitle).foregroundStyle(.white))
                        .onTapGesture {
                            if viewModel.canTap {
                                Task {
                                    await viewModel.handleUserTap(index: index)
                                }
                            }
                        }
                    }
                }
                
                HStack(spacing: 20) {
                    ForEach(2..<4) { index in
                        FlashableImage(
                            index: index,
                            opacity: viewModel.currentPlayer == .user ? 1 : 0.7,
                            showBorder: viewModel.selectedIndex == index
                        )
                        .overlay(Text(index.formatted()).font(.largeTitle).foregroundStyle(.white))
                        .onTapGesture {
                            if viewModel.canTap {
                                Task {
                                    await viewModel.handleUserTap(index: index)
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
                ZStack {
                    Color.black.opacity(0.5)
                        .ignoresSafeArea()
                        .transition(.opacity)
                    GameOverView {
                        Task {
                            await viewModel.resetGame()
                        }
                    } end: {
                        dismiss()
                    }
                }
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
