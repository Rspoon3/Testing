//
//  CarouselView.swift
//  Testing
//
//  Created by Richard Witherspoon on 12/6/23.
//

import SwiftUI

struct CarouselView: View {
    @StateObject private var viewModel = CarouselViewModel()
    private let colors: [Color] = [.teal, .blue, .green, .orange, .purple, .red]
    
    var body: some View {
        GeometryReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: viewModel.spacing) {
                    ForEach(0..<viewModel.maxValue, id: \.self) { i in
                        let v = i % colors.count
                        colors[v]
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .aspectRatio(2, contentMode: .fit)
                            .frame(width: proxy.size.width - viewModel.spacing * 4)
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
            .safeAreaPadding(.horizontal, viewModel.spacing * 2)
            .scrollPosition(id: $viewModel.id)
//            .onAppear {
//                viewModel.id = 25
//            }
//            .task {
//                try? await Task.sleep(for: .seconds(1))
//                withAnimation {
//                    viewModel.id = 250
//                }
//            }
        }
    }
}

#Preview {
    CarouselView()
}



