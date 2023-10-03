//
//  ContentView.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

struct ContentView: View {
    @State var show = true
    
    var body: some View {
        Button("test") {
            show.toggle()
        }
        .fullScreenCover(isPresented: $show) {
            ContentView3(show: $show)
        }
    }
}

struct ContentView3: View {
    @State private var circleScale = 0.0
    @State private var showText = true
    @State private var scale: CGFloat = 1
    @State private var opacity: CGFloat = 1
    @State private var test: CGFloat = 300
    @State private var imageHeight: CGFloat = 0
    @Namespace var namespace
    
    @Binding var show: Bool
    
    
    var body: some View {
        GeometryReader { geo in
            VStack(alignment: .leading, spacing: 0) {
                ZStack(alignment: .bottom) {
                    LinearGradient(
                        colors: [
                            Color(hex: "#0077FF"),
                            Color(hex: "#017BFF"),
                            Color(hex: "#0688FF"),
                            Color(hex: "#0D9DFF"),
                            Color(hex: "#17BBFF"),
                            Color(hex: "#24E0FF"),
                            Color(hex: "#2EFFFF")
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(maxWidth: .infinity)
                    .ignoresSafeArea(edges: .top)
                    .padding(.bottom, 2)
                    
                    
                    Image("door.offers.white")
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                    
                    Image("door.offers")
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(scale)
                        .opacity(opacity)
                        .background {
                            GeometryReader { geo in
                                Color.clear
                                    .onAppear {
                                        imageHeight = geo.size.height
                                    }
                                Circle()
                                    .scale(circleScale)
                                    .foregroundColor(.white)
                            }
                        }
                }
                
                if showText {
                    VStack(alignment: .leading, spacing: 0) {
                        Text("This is it!")
                        Text("This is it!")
                        Text("This is it!")
                        Text("This is it!")
                    }
                    .font(.largeTitle)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
                    .transition(.move(edge: .bottom))
                } else {
                    Spacer(minLength: geo.size.height / 2 - imageHeight / 2)
                }
            }
        }
        .onTapGesture {
            start()
        }
    }
    
    func start() {
        withAnimation(.default) {
            showText.toggle()
        }
        
        Task {
            try await Task.sleep(for: .milliseconds(800))
            withAnimation(.linear(duration: 0.5)) {
                scale = (scale == 1 ? 1.5 : 1)
                opacity = (opacity == 1 ? 0 : 1)
            }
            
            try await Task.sleep(for: .milliseconds(400))
            
            withAnimation(.linear(duration: 0.5)) {
                circleScale = 3.5
            }

            try await Task.sleep(for: .milliseconds(1800))

            var transaction = Transaction()
            transaction.disablesAnimations = true

             // add custom animation for presenting and dismissing the FullScreenCover
             transaction.animation = .linear(duration: 1)
            
            withTransaction(transaction) {
               show.toggle()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
struct TestView: View {
    var body: some View {
        GeometryReader { geo in
            Arc(
                startAngle: .degrees(0),
                endAngle: .degrees(360/2),
                clockwise: true
            )
            .foregroundColor(.black)
            .frame(width: geo.size.width * 0.4)
            .position(x: geo.frame(in: .local).minX, y: 0)
            
            Arc(
                startAngle: .degrees(0),
                endAngle: .degrees(360/2),
                clockwise: true
            )
            .foregroundColor(.red)
            .frame(width: geo.size.width * 0.8)
            .position(x: geo.frame(in: .local).midX, y: 0)
            .zIndex(2)
            
            Arc(
                startAngle: .degrees(0),
                endAngle: .degrees(360/2),
                clockwise: true
            )
            .foregroundColor(.orange)
            .frame(width: geo.size.width * 0.4)
            .position(x: geo.frame(in: .local).maxX, y: 0)
        }
    }
}

struct Arc: Shape {
    var startAngle: Angle
    var endAngle: Angle
    var clockwise: Bool
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.addArc(center: CGPoint(x: rect.midX, y: rect.midY), radius: rect.width / 2, startAngle: startAngle, endAngle: endAngle, clockwise: clockwise)
        
        return path
    }
}
