import SwiftUI
import SpriteKit

struct PhysicsBallClockView: View {
    let showMilliseconds: Bool
    @State private var scene: PhysicsBallScene?
    @State private var currentTime = Date()
    
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    init(showMilliseconds: Bool = false) {
        self.showMilliseconds = showMilliseconds
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.ignoresSafeArea()
                
                SpriteView(scene: makeScene(size: geometry.size), 
                          options: [.allowsTransparency, .ignoresSiblingOrder])
                    .ignoresSafeArea()
                
                VStack {
                    HStack {
                        VStack(alignment: .leading) {
                            Label("Hours", systemImage: "circle.fill")
                                .foregroundColor(.orange)
                            Label("Minutes", systemImage: "circle.fill")
                                .foregroundColor(.blue)
                            Label("Seconds", systemImage: "circle.fill")
                                .foregroundColor(.green)
                            if showMilliseconds {
                                Label("Milliseconds", systemImage: "circle.fill")
                                    .foregroundColor(.purple)
                            }
                        }
                        .font(.caption)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                        
                        Spacer()
                        
                        Text(currentTime.formatted(date: .omitted, time: .complete))
                            .font(.headline)
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(10)
                    }
                    .padding()
                    
                    Spacer()
                }
            }
        }
        .preferredColorScheme(.dark)
        .onReceive(timer) { _ in
            currentTime = Date()
        }
    }
    
    private func makeScene(size: CGSize) -> PhysicsBallScene {
        let scene = PhysicsBallScene()
        scene.size = size
        scene.scaleMode = .resizeFill
        scene.backgroundColor = .clear
        scene.showMilliseconds = showMilliseconds
        return scene
    }
}

#Preview {
    PhysicsBallClockView(showMilliseconds: true)
}