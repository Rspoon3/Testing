//
//  BouncingBallScene.swift
//  Testing
//
//  Created by Ricky on 3/28/25.
//

import SwiftUI
import SpriteKit

import SwiftUI
import MetalKit
import simd

// MARK: - Shared Structures

struct Ball3 {
    var position: SIMD2<Float>
    var velocity: SIMD2<Float>
    var color: SIMD4<Float> // r, g, b, a
    var isInfectious: Bool
}

struct SceneConstants {
    var width: Float
    var height: Float
    var ballRadius: Float
    var deltaTime: Float
    var ballCount: UInt32
    var infectiousColor: SIMD4<Float>
    var regularColor: SIMD4<Float>
}

// MARK: - Metal Renderer

class MetalBallsRenderer: NSObject, MTKViewDelegate {
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let pipelineState: MTLComputePipelineState
    private let renderPipelineState: MTLRenderPipelineState
    
    private var ballsBuffer: MTLBuffer
    private var constantsBuffer: MTLBuffer
    private var infectiousModeBuffer: MTLBuffer
    
    private var balls: [Ball3] = []
    private var lastUpdateTime: Date = Date()
    private let ballCount = 50
    private let ballRadius: Float = 10.0
    private let speed: Float = 2.447 * 60.0
    
    enum InfectionMode: Int32 {
        case blueInfectsRed = 0
        case redInfectsBlue = 1
    }
    
    private var infectionMode: InfectionMode = .blueInfectsRed
    
    init?(metalView: MTKView) {
        guard let device = MTLCreateSystemDefaultDevice(),
              let commandQueue = device.makeCommandQueue() else {
            return nil
        }
        
        self.device = device
        self.commandQueue = commandQueue
        
        // Set up Metal view
        metalView.device = device
        metalView.clearColor = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        metalView.framebufferOnly = false
        
        // Create compute pipeline state
        guard let computeShaderURL = Bundle.main.url(forResource: "BallsShader", withExtension: "metal"),
              let computeShaderSource = try? String(contentsOf: computeShaderURL),
              let computeLibrary = try? device.makeLibrary(source: computeShaderSource, options: nil),
              let updateKernel = computeLibrary.makeFunction(name: "updateBalls"),
              let pipelineState = try? device.makeComputePipelineState(function: updateKernel) else {
            return nil
        }
        
        // Create render pipeline state
        let renderPipelineDescriptor = MTLRenderPipelineDescriptor()
        renderPipelineDescriptor.colorAttachments[0].pixelFormat = metalView.colorPixelFormat
        
        guard let vertexFunction = computeLibrary.makeFunction(name: "vertexShader"),
              let fragmentFunction = computeLibrary.makeFunction(name: "fragmentShader") else {
            return nil
        }
        
        renderPipelineDescriptor.vertexFunction = vertexFunction
        renderPipelineDescriptor.fragmentFunction = fragmentFunction
        
        guard let renderPipelineState = try? device.makeRenderPipelineState(descriptor: renderPipelineDescriptor) else {
            return nil
        }
        
        self.renderPipelineState = renderPipelineState
        self.pipelineState = pipelineState
        
        // Initialize balls
        let viewWidth = Float(metalView.bounds.width)
        let viewHeight = Float(metalView.bounds.height)
        
        // Initialize balls with random positions and velocities
        var initialBalls: [Ball3] = []
        for i in 0..<ballCount {
            let x = Float.random(in: ballRadius...(viewWidth - ballRadius))
            let y = Float.random(in: ballRadius...(viewHeight - ballRadius))
            let angle = Float.random(in: 0..<(2 * Float.pi))
            
            let isBlue = i == 0
            let color: SIMD4<Float> = isBlue ? SIMD4<Float>(0, 0, 1, 1) : SIMD4<Float>(1, 0, 0, 1)
            
            initialBalls.append(Ball3(
                position: SIMD2<Float>(x, y),
                velocity: SIMD2<Float>(cos(angle) * speed, sin(angle) * speed),
                color: color,
                isInfectious: isBlue
            ))
        }
        
        self.balls = initialBalls
        
        // Create Metal buffers
        guard let ballsBuffer = device.makeBuffer(length: MemoryLayout<Ball3>.stride * ballCount, options: .storageModeShared),
              let constantsBuffer = device.makeBuffer(length: MemoryLayout<SceneConstants>.size, options: .storageModeShared),
              let infectiousModeBuffer = device.makeBuffer(length: MemoryLayout<Int32>.size, options: .storageModeShared) else {
            return nil
        }
        
        self.ballsBuffer = ballsBuffer
        self.constantsBuffer = constantsBuffer
        self.infectiousModeBuffer = infectiousModeBuffer

        super.init()
        
        // Update buffers with initial data
        updateBuffers(viewWidth: viewWidth, viewHeight: viewHeight, deltaTime: 1/60)
    }
    
    func updateBuffers(viewWidth: Float, viewHeight: Float, deltaTime: Float) {
        // Update balls buffer
        let ballsPtr = ballsBuffer.contents().bindMemory(to: Ball3.self, capacity: ballCount)
        for i in 0..<ballCount {
            ballsPtr[i] = balls[i]
        }
        
        // Update constants buffer
        let constantsPtr = constantsBuffer.contents().bindMemory(to: SceneConstants.self, capacity: 1)
        constantsPtr.pointee = SceneConstants(
            width: viewWidth,
            height: viewHeight,
            ballRadius: ballRadius,
            deltaTime: deltaTime,
            ballCount: UInt32(ballCount),
            infectiousColor: infectionMode == .blueInfectsRed ? SIMD4<Float>(0, 0, 1, 1) : SIMD4<Float>(1, 0, 0, 1),
            regularColor: infectionMode == .blueInfectsRed ? SIMD4<Float>(1, 0, 0, 1) : SIMD4<Float>(0, 0, 1, 1)
        )
        
        // Update infection mode buffer
        let modePtr = infectiousModeBuffer.contents().bindMemory(to: Int32.self, capacity: 1)
        modePtr.pointee = Int32(infectionMode.rawValue)
    }
    
    func draw(in view: MTKView) {
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let drawable = view.currentDrawable else {
            return
        }
        
        let currentTime = Date()
        let deltaTime = Float(currentTime.timeIntervalSince(lastUpdateTime))
        lastUpdateTime = currentTime
        
        // Update buffers with current data
        updateBuffers(
            viewWidth: Float(view.bounds.width),
            viewHeight: Float(view.bounds.height),
            deltaTime: deltaTime
        )
        
        // Dispatch compute command encoder
        guard let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            return
        }
        
        computeEncoder.setComputePipelineState(pipelineState)
        computeEncoder.setBuffer(ballsBuffer, offset: 0, index: 0)
        computeEncoder.setBuffer(constantsBuffer, offset: 0, index: 1)
        computeEncoder.setBuffer(infectiousModeBuffer, offset: 0, index: 2)
        
        let threadsPerGrid = MTLSize(width: ballCount, height: 1, depth: 1)
        let threadsPerThreadgroup = MTLSize(width: min(pipelineState.maxTotalThreadsPerThreadgroup, ballCount), height: 1, depth: 1)
        
        computeEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
        computeEncoder.endEncoding()
        
        // Read back results from GPU
        let ballsPtr = ballsBuffer.contents().bindMemory(to: Ball3.self, capacity: ballCount)
        for i in 0..<ballCount {
            balls[i] = ballsPtr[i]
        }
        
        // Check for mode switching
        checkInfectionModeSwitch()
        
        // Render balls
        if let renderPassDescriptor = view.currentRenderPassDescriptor,
           let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
            renderEncoder.setRenderPipelineState(renderPipelineState)
            renderEncoder.setVertexBuffer(ballsBuffer, offset: 0, index: 0)
            renderEncoder.setVertexBuffer(constantsBuffer, offset: 0, index: 1)
            renderEncoder.drawPrimitives(type: .point, vertexStart: 0, vertexCount: ballCount)
            renderEncoder.endEncoding()
        }
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Handle view resize
    }
    
    private func checkInfectionModeSwitch() {
        let redBalls = balls.filter { $0.color.x > 0.5 && $0.color.y < 0.5 && $0.color.z < 0.5 }
        let blueBalls = balls.filter { $0.color.x < 0.5 && $0.color.y < 0.5 && $0.color.z > 0.5 }
        
        if infectionMode == .blueInfectsRed && redBalls.count == 1 {
            infectionMode = .redInfectsBlue
            updateInfectiousFlag(isRed: true)
        } else if infectionMode == .redInfectsBlue && blueBalls.count == 1 {
            infectionMode = .blueInfectsRed
            updateInfectiousFlag(isRed: false)
        }
    }
    
    private func updateInfectiousFlag(isRed: Bool) {
        for i in 0..<balls.count {
            let isTargetColor = isRed ?
                (balls[i].color.x > 0.5 && balls[i].color.y < 0.5 && balls[i].color.z < 0.5) :
                (balls[i].color.x < 0.5 && balls[i].color.y < 0.5 && balls[i].color.z > 0.5)
            
            if isTargetColor {
                balls[i].isInfectious = true
            } else {
                balls[i].isInfectious = false
            }
        }
    }
}

// MARK: - SwiftUI View

struct MetalBouncingBallsView: View {
    @State private var renderer: MetalBallsRenderer?
    
    var body: some View {
        MetalViewRepresentable(renderer: $renderer)
            .ignoresSafeArea()
            .onDisappear {
                // Clean up
                renderer = nil
            }
    }
}

struct MetalViewRepresentable: UIViewRepresentable {
    @Binding var renderer: MetalBallsRenderer?
    
    func makeUIView(context: Context) -> MTKView {
        let mtkView = MTKView()
        mtkView.enableSetNeedsDisplay = false
        mtkView.preferredFramesPerSecond = 60
        mtkView.framebufferOnly = false
        
        renderer = MetalBallsRenderer(metalView: mtkView)
        mtkView.delegate = renderer
        
        return mtkView
    }
    
    func updateUIView(_ uiView: MTKView, context: Context) {
        // Nothing to update
    }
}

#Preview {
    MetalBouncingBallsView()
}
