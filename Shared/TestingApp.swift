//
//  TestingApp.swift
//  Shared
//
//  Created by Richard Witherspoon on 8/9/20.
//

import SwiftUI

@main
struct TestingApp: App {
    @StateObject private var viewModel = PKCanvasViewModel()
    @State private var count = 0
    
    var body: some Scene {
        WindowGroup {
//            ContentView2()
//            Patrick()
            PatrickHorizontal()
//            PKCanvas(viewModel: viewModel)
////            Color.blue
//                .border(.red)
//                .overlay {
//                    GeometryReader { geo in
//                        VStack {
//                            Text(geo.size.width.formatted())
//                            Text(geo.size.height.formatted())
//                            Text(count.formatted())
//                        }
//                        .onTapGesture {
//                            count += 1
//                        }
//                    }
//                }
////                .ignoresSafeArea(.all)
//                .onAppear {
//                    Task {
//                        try await Task.sleep(for: .seconds(1))
//                        viewModel.viewDidLayoutSubviews()
//                    }
//                }
        }
    }
}
