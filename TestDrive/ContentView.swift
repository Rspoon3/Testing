//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

extension Color {
    static let darkPurple = Color(red: 55/255, green: 17/255, blue: 100/255)
}

struct ContentView: View {
    @State private var boarderOpacity: CGFloat = 0
    @State private var boxViewModel = BoxViewModel()
    @State private var boarderAngle: CGFloat = 90
    @State private var state: ExpandedState = .collapsed
    @State private var showCount = false
    @State private var trapOffset: CGFloat = 0
    private let height: CGFloat = 56
    private let cornerRadius: CGFloat = 22
    @State private var startNavigationAnimation = false
    
    enum ExpandedState: String {
        case collapsed
        case withText
        case boxOnly
        
        var width: CGFloat {
            switch self {
            case .collapsed:
                return 3
            case .withText:
                return 124
            case .boxOnly:
                return 56
            }
        }
    }
    
    @State private var goToCenter = false
    
    var body: some View {
        List {
            Text(state.rawValue)
            Text("Disabled: \(state != .boxOnly)")
            ForEach(0..<100, id: \.self) { i in
                Button("This is row \(i) and I like it very much so the thing that I need to do is go to bed") {
                    print(i)
                }
            }
        }
        .overlay {
            boxes
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                toggleButton
            }
        }
    }
    
    @ViewBuilder
    private var boxes: some View {
        if startNavigationAnimation {
            Box(viewModel: boxViewModel)
                .padding(.horizontal)
        } else {
            Button {
                startNavigationAnimation = true
            } label : {
                ZStack(alignment: .bottomTrailing) {
                    spinAndWinFAB
                        .overlay(alignment: .leading) {
                            trap
                        }
                    
                    circleDot
                }
            }
            .buttonStyle(PressScaleButtonStyle())
            .disabled(state != .boxOnly)
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .bottomTrailing
            )
            .padding(.horizontal)
        }
    }
    
    private var toggleButton: some View {
        Button("Toggle") {
            startBoxAnimations()
        }
    }
    
    func startLoopedAnimation(after delay: TimeInterval) {
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            withAnimation(.linear(duration: 1.2)) {
                boarderAngle += 360
            }
            
            withAnimation(
                .linear(duration: 0.25)
            ) {
                boarderOpacity = 1
            }
            
            withAnimation(
                .linear(duration: 0.25)
                .delay(1)
            ) {
                boarderOpacity = 0
            }
            
            // Schedule next animation after 5 seconds
            startLoopedAnimation(after: 5)
        }
    }
    
    private func startBoxAnimations() {
        guard state == .collapsed else { return }
        
        // Border shimmer. 2 second initially delay, 5 seconds in a loop after that
        startLoopedAnimation(after: 2)

        // Cover, expansion state, dot. All of these are done linearly
        Task {
            try? await Task.sleep(for: .milliseconds(100))
            withAnimation(.timingCurve(0.32, 0.05, 0.82, 0.69, duration: 0.2)) {
                state = .withText
            }
            
            try? await Task.sleep(for: .milliseconds(200))
            withAnimation(.timingCurve(0.32, 0.05, 0.82, 0.69, duration: 0.2)) {
                trapOffset = -164
            }
            
            try? await Task.sleep(for: .milliseconds(5200))
            withAnimation(.timingCurve(0.49, 0.01, 0.76, 0.81, duration: 0.3)) {
                state = .boxOnly
            }
            
            try? await Task.sleep(for: .milliseconds(1100))
            withAnimation(.timingCurve(0.49, 0.01, 0.44, 1, duration: 0.3)) {
                showCount = true
            }
        }
    }
    
    private var circleDot: some View {
        Circle()
            .foregroundStyle(.red)
            .overlay {
                Text("6")
                    .foregroundStyle(.white)
                    .font(.caption)
            }
            .frame(width: 20)
            .opacity(showCount ? 1 : 0)
            .scaleEffect(showCount ? 1 : 0.6)
            .zIndex(showCount ? 1 : 0)
            .offset(x: 4, y: 4)
    }
    
    private var trap: some View {
        HStack(spacing: 0) {
            Rectangle()
                .frame(width: 124)
            RightSlantTriangle()
                .frame(width: 40)
        }
        .offset(x: trapOffset)
        .foregroundStyle(.purple)
        .frame(height: height)
        .mask(alignment: .leading) {
            RoundedRectangle(cornerRadius: cornerRadius)
                .frame(width: state.width)
        }
    }
    
    private var spinAndWinFAB: some View {
        HStack(spacing: 12) {
            Image("spinAndWinBox")
                .resizable()
                .scaledToFit()
                .frame(width: 28)
                .padding(.leading, 14)
            
            Text("6 Spins")
                .fixedSize()
                .font(.footnote)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(
            width: state.width,
            height: height,
            alignment: .leading
        )
        .background(Color.darkPurple)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .overlay {
            RoundedRectangle(cornerRadius: cornerRadius)
                .strokeBorder(style: StrokeStyle(lineWidth: 3))
                .foregroundStyle(.purple)
        }
        .overlay {
            AngularGradient(
                gradient: Gradient(
                    stops: [
                        .init(
                            color: .purple,
                            location: 0
                        ),
                        .init(
                            color: .purple,
                            location: 0.76
                        ),
                        .init(
                            color: .white,
                            location: 1
                        )
                    ]
                ),
                center: .center,
                angle: .degrees(boarderAngle)
            )
            .opacity(boarderOpacity)
            .mask(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .strokeBorder(style: StrokeStyle(lineWidth: 3)) // inside
            )
        }
    }
}

#Preview {
    NavigationStack {
        ContentView()
    }
}
import SwiftUI

struct PressScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.86 : 1.0)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}
