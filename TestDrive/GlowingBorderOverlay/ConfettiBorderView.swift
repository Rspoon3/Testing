//
//  ConfettiBorderView.swift
//  TestDrive
//

import SwiftUI
import Vortex

/// A repeating shower of multicolored confetti, backed by Vortex.
///
/// The `.confetti` preset has `birthRate: 0`, meaning it only spawns particles
/// in response to `proxy.burst()`. We trigger a burst on appear and then keep
/// bursting periodically so the effect persists for the whole warning window.
struct ConfettiBorderView: View {

    // MARK: - Body

    var body: some View {
        VortexViewReader { proxy in
            VortexView(.confetti) {
                Rectangle()
                    .fill(.white)
                    .frame(width: 16, height: 16)
                    .tag("square")
                Circle()
                    .fill(.white)
                    .frame(width: 16, height: 16)
                    .tag("circle")
            }
            .ignoresSafeArea()
            .task {
                proxy.burst()
                while !Task.isCancelled {
                    try? await Task.sleep(for: .seconds(2))
                    proxy.burst()
                }
            }
        }
    }
}

#Preview {
    ConfettiBorderView()
        .frame(width: 800, height: 500)
        .background(.black)
}
