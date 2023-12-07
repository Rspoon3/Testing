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
                    LazyHStack {
                        ForEach(0..<viewModel.maxValue, id: \.self) { i in
                            let v = i % colors.count
                            colors[v]
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .aspectRatio(16.0 / 9.0, contentMode: .fit)
                                .frame(width: proxy.size.width - viewModel.safeAreaPadding * 2)
                                .overlay {
                                    Text(i.formatted())
                                        .font(.largeTitle)
                                }
                                .visualEffect { [viewModel] content, geometryProxy in
                                    content
                                        .scaleEffect(
                                            y: viewModel.yScale(using: geometryProxy)
                                        )
                                }
                        }
                    }
                    .scrollTargetLayout()
                }
                .scrollTargetBehavior(.viewAligned)
                .safeAreaPadding(.horizontal, viewModel.safeAreaPadding)
                .scrollPosition(id: $viewModel.id)
                .introspect(.scrollView, on: .iOS(.v13, .v14, .v15, .v16, .v17)) { scrollView in
                    viewModel.set(scrollView)
                }
            }
        }
    }
}

#Preview {
    CarouselView()
}



