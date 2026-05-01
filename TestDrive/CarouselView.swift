//
//  CarouselView.swift
//  Testing
//
//  Created by Richard Witherspoon on 12/6/23.
//

import SwiftUI
import SwiftUIIntrospect

@MainActor
struct CarouselView: View {
    @StateObject private var viewModel = CarouselViewModel()
    private let colors: [Color] = [.teal, .blue, .green, .orange, .purple, .red]

    var body: some View {
        VStack {
            GeometryReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack(spacing: 10) {
                        ForEach(0..<viewModel.maxValue, id: \.self) { i in
                            let v = i % colors.count
                            colors[v]
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .frame(width: viewModel.manager.cellWidth, height: viewModel.manager.cellHeight)
                                .overlay {
                                    Text(i.formatted())
                                        .font(.largeTitle)
                                }
                                .visualEffect { [viewModel] content, geometryProxy in
                                    content
                                        .scaleEffect(
                                            y: viewModel.yScale(using: geometryProxy, i: i)
                                        )
                                }
                        }
                    }
                    .scrollTargetLayout()
                    .padding(.horizontal, 24)
                }
                .scrollTargetBehavior(.viewAligned)
                .scrollPosition(id: $viewModel.id)
                .introspect(.scrollView, on: .iOS(.v13, .v14, .v15, .v16, .v17)) { scrollView in
                    viewModel.set(scrollView)
                }
                .task {
                    try? await Task.sleep(for: .seconds(1))
                    withAnimation {
                        viewModel.id = 50
                    }
                }
            }
        }
    }
}

#Preview {
    CarouselView()
}



