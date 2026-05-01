//
//  Box.swift
//  Testing
//
//  Created by Ricky Witherspoon on 6/2/25.
//

import SwiftUI
import Combine

@MainActor
final class BoxViewModel: ObservableObject {
    @Published var fullScreen = false
    @Published var circleSizeState: CircleSizeState = .small
    @Published var boxOpacity: CGFloat = 1
    @Published var boxScale: CGFloat = 1
    @Published var boxSize: CGFloat = 28
    let cornerRadius: CGFloat = 22
    let height: CGFloat = 56
    
    @MainActor
    enum CircleSizeState: CGFloat {
        case small, medium, fullScreen
        
        var size: CGFloat {
            switch self {
            case .small: 56
            case .medium: 200
            case .fullScreen: UIScreen.main.bounds.height * 1.5
            }
        }
        
        var cornerRadius: CGFloat {
            switch self {
            case .small: 22
            case .medium, .fullScreen: size / 2
            }
        }
    }
    
    func start() async throws {
        withAnimation(.linear(duration: 0.3)) {
            fullScreen.toggle()
            circleSizeState = .medium
            boxScale = 1
            boxSize = 80
        }
        
        try await Task.sleep(for: .seconds( 0.6))
        
        withAnimation(.linear(duration: 0.3)) {
            circleSizeState = .fullScreen
        }
        
        try await Task.sleep(for: .seconds(0.8))
        
        withAnimation(.easeInOut(duration: 1).repeatForever(autoreverses: true)) {
            boxScale = 1.075
        }
    }
    
    func animateDismissal() {
        withAnimation(.easeInOut(duration: 0.2)) {
            boxOpacity = 0
        }
    }
}

struct Box: View {
    @ObservedObject var viewModel: BoxViewModel
    
    var body: some View {
        RoundedRectangle(cornerRadius: viewModel.circleSizeState.cornerRadius)
            .foregroundStyle(Color.darkPurple)
            .frame(
                width: viewModel.circleSizeState.size,
                height: viewModel.circleSizeState.size
            )
            .overlay {
                RoundedRectangle(cornerRadius: viewModel.circleSizeState.cornerRadius)
                    .strokeBorder(style: StrokeStyle(lineWidth: 3))
                    .foregroundStyle(.purple)
            }
            .overlay {
                Image("spinAndWinBox")
                    .resizable()
                    .scaledToFit()
                    .frame(width: viewModel.boxSize)
                    .scaleEffect(viewModel.boxScale)
                    .opacity(viewModel.boxOpacity)
                    .onTapGesture {
                        viewModel.animateDismissal()
                    }
            }
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: viewModel.fullScreen ? .center : .bottomTrailing
            )
            .task {
                try? await viewModel.start()
            }
    }
}

#Preview {
    Box(viewModel: .init())
}
