import SpriteKit
import CoreMotion
import UIKit

class PhysicsBallScene: SKScene, SKPhysicsContactDelegate {
    var showMilliseconds = false
    
    private var motionManager = CMMotionManager()
    private var hourBalls: [SKShapeNode] = []
    private var minuteBalls: [SKShapeNode] = []
    private var secondBalls: [SKShapeNode] = []
    private var millisecondBalls: [SKShapeNode] = []
    
    private var lastHour = -1
    private var lastMinute = -1
    private var lastSecond = -1
    private var lastMillisecond = -1
    
    // Track balls that have already triggered haptics
    private var ballsWithHaptics: Set<ObjectIdentifier> = []
    
    private let ballRadius: CGFloat = 15
    private let hourBallRadius: CGFloat = 15
    private let minuteBallRadius: CGFloat = 10
    private let secondBallRadius: CGFloat = 6
    private let millisecondBallRadius: CGFloat = 4
    
    // Collision categories
    private let hourBallCategory: UInt32 = 0x1 << 0
    private let minuteBallCategory: UInt32 = 0x1 << 1
    private let secondBallCategory: UInt32 = 0x1 << 2
    private let millisecondBallCategory: UInt32 = 0x1 << 3
    private let boundaryCategory: UInt32 = 0x1 << 4
    
    // Haptic feedback generators
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    
    // Haptic throttling
    private var lastHapticTime: TimeInterval = 0
    private let hapticCooldown: TimeInterval = 0.1 // Minimum time between haptic events
    
    // Update throttling
    private var lastUpdateTime: TimeInterval = 0
    
    override func didMove(to view: SKView) {
        setupPhysics()
        setupBoundaries()
        startMotionUpdates()
        initializeTimeBasedBalls()
        
        // Set up collision detection
        physicsWorld.contactDelegate = self
        
        // Prepare haptic generators
        lightImpact.prepare()
        mediumImpact.prepare()
        heavyImpact.prepare()
    }
    
    override func update(_ currentTime: TimeInterval) {
        // Throttle updates based on whether milliseconds are enabled
        let updateInterval: TimeInterval = showMilliseconds ? 0.01 : 0.1
        
        if currentTime - lastUpdateTime >= updateInterval {
            updateTimeBasedBalls()
            lastUpdateTime = currentTime
        }
    }
    
    private func setupPhysics() {
        physicsWorld.gravity = CGVector(dx: 0, dy: -9.8)
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsBody?.friction = 0.3
        physicsBody?.restitution = 0.2
    }
    
    private func setupBoundaries() {
        // Create invisible walls with collision categories
        let leftWall = SKNode()
        leftWall.physicsBody = SKPhysicsBody(edgeFrom: CGPoint(x: 0, y: 0), to: CGPoint(x: 0, y: frame.height))
        leftWall.physicsBody?.categoryBitMask = boundaryCategory
        addChild(leftWall)
        
        let rightWall = SKNode()
        rightWall.physicsBody = SKPhysicsBody(edgeFrom: CGPoint(x: frame.width, y: 0), to: CGPoint(x: frame.width, y: frame.height))
        rightWall.physicsBody?.categoryBitMask = boundaryCategory
        addChild(rightWall)
        
        let floor = SKNode()
        floor.physicsBody = SKPhysicsBody(edgeFrom: CGPoint(x: 0, y: 0), to: CGPoint(x: frame.width, y: 0))
        floor.physicsBody?.friction = 0.5
        floor.physicsBody?.categoryBitMask = boundaryCategory
        addChild(floor)
        
        let ceiling = SKNode()
        ceiling.physicsBody = SKPhysicsBody(edgeFrom: CGPoint(x: 0, y: frame.height), to: CGPoint(x: frame.width, y: frame.height))
        ceiling.physicsBody?.categoryBitMask = boundaryCategory
        addChild(ceiling)
    }
    
    private func startMotionUpdates() {
        if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 1.0 / 60.0
            motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
                guard let motion = motion, error == nil else { return }
                self?.physicsWorld.gravity = CGVector(
                    dx: motion.gravity.x * 9.8,
                    dy: motion.gravity.y * 9.8
                )
            }
        }
    }
    
    private func initializeTimeBasedBalls() {
        let calendar = Calendar.current
        let now = Date()
        
        let hour = calendar.component(.hour, from: now) % 12
        let minute = calendar.component(.minute, from: now)
        let second = calendar.component(.second, from: now)
        let nanosecond = calendar.component(.nanosecond, from: now)
        
        // Create initial balls
        for _ in 0..<(hour == 0 ? 12 : hour) {
            dropHourBall()
        }
        
        for _ in 0..<minute {
            dropMinuteBall()
        }
        
        for _ in 0..<second {
            dropSecondBall()
        }
        
        // Handle milliseconds if enabled
        if showMilliseconds {
            let millisecond = nanosecond / 1_000_000
            let currentMillisecond = millisecond / 10 // Group into 10ms intervals
            for _ in 0..<Int(currentMillisecond) {
                dropMillisecondBall()
            }
            lastMillisecond = Int(currentMillisecond)
        }
        
        lastHour = hour
        lastMinute = minute
        lastSecond = second
    }
    
    private func updateTimeBasedBalls() {
        let calendar = Calendar.current
        let now = Date()
        
        let hour = calendar.component(.hour, from: now) % 12
        let minute = calendar.component(.minute, from: now)
        let second = calendar.component(.second, from: now)
        let nanosecond = calendar.component(.nanosecond, from: now)
        let millisecond = nanosecond / 1_000_000
        
        // Handle hours
        if hour != lastHour {
            if hour == 0 {
                // Clear all hour balls at 12
                clearBalls(&hourBalls)
            }
            dropHourBall()
            lastHour = hour
        }
        
        // Handle minutes
        if minute != lastMinute {
            if minute == 0 {
                // Clear all minute balls at 60
                clearBalls(&minuteBalls)
            }
            dropMinuteBall()
            lastMinute = minute
        }
        
        // Handle seconds
        if second != lastSecond {
            if second == 0 {
                // Clear all second balls at 60 (top of minute)
                clearBalls(&secondBalls)
                // Also clear millisecond balls at top of minute
                if showMilliseconds {
                    clearBalls(&millisecondBalls)
                }
            }
            dropSecondBall()
            lastSecond = second
        }
        
        // Handle milliseconds (only if enabled)
        if showMilliseconds {
            let currentMillisecond = millisecond / 10 // Group into 10ms intervals
            if currentMillisecond != lastMillisecond {
                dropMillisecondBall()
                lastMillisecond = currentMillisecond
            }
        }
    }
    
    private func dropHourBall() {
        let ball = createBall(radius: hourBallRadius, color: .orange, category: hourBallCategory)
        ball.position = CGPoint(x: CGFloat.random(in: 50...frame.width-50), y: frame.height - 50)
        hourBalls.append(ball)
        addChild(ball)
        
        // Add some initial horizontal velocity for variety
        ball.physicsBody?.velocity = CGVector(dx: CGFloat.random(in: -50...50), dy: 0)
    }
    
    private func dropMinuteBall() {
        let ball = createBall(radius: minuteBallRadius, color: .blue, category: minuteBallCategory)
        ball.position = CGPoint(x: CGFloat.random(in: 50...frame.width-50), y: frame.height - 50)
        minuteBalls.append(ball)
        addChild(ball)
        
        ball.physicsBody?.velocity = CGVector(dx: CGFloat.random(in: -50...50), dy: 0)
    }
    
    private func dropSecondBall() {
        let ball = createBall(radius: secondBallRadius, color: .green, category: secondBallCategory)
        ball.position = CGPoint(x: CGFloat.random(in: 50...frame.width-50), y: frame.height - 50)
        secondBalls.append(ball)
        addChild(ball)
        
        ball.physicsBody?.velocity = CGVector(dx: CGFloat.random(in: -50...50), dy: 0)
    }
    
    private func dropMillisecondBall() {
        let ball = createBall(radius: millisecondBallRadius, color: .purple, category: millisecondBallCategory)
        ball.position = CGPoint(x: CGFloat.random(in: 50...frame.width-50), y: frame.height - 50)
        millisecondBalls.append(ball)
        addChild(ball)
        
        ball.physicsBody?.velocity = CGVector(dx: CGFloat.random(in: -30...30), dy: 0)
    }
    
    private func createBall(radius: CGFloat, color: UIColor, category: UInt32) -> SKShapeNode {
        let ball = SKShapeNode(circleOfRadius: radius)
        ball.fillColor = color
        ball.strokeColor = .clear  // Remove stroke for cleaner look
        ball.lineWidth = 0
        
        ball.physicsBody = SKPhysicsBody(circleOfRadius: radius)
        ball.physicsBody?.isDynamic = true
        ball.physicsBody?.restitution = 0.4
        ball.physicsBody?.friction = 0.3
        ball.physicsBody?.mass = radius / 10
        ball.physicsBody?.allowsRotation = true
        
        // Set up collision detection
        ball.physicsBody?.categoryBitMask = category
        ball.physicsBody?.contactTestBitMask = hourBallCategory | minuteBallCategory | secondBallCategory | millisecondBallCategory | boundaryCategory
        ball.physicsBody?.collisionBitMask = hourBallCategory | minuteBallCategory | secondBallCategory | millisecondBallCategory | boundaryCategory
        
        return ball
    }
    
    private func clearBalls(_ balls: inout [SKShapeNode]) {
        for ball in balls {
            // Remove ball from haptics tracking
            let ballId = ObjectIdentifier(ball)
            ballsWithHaptics.remove(ballId)
            
            // Fade out animation
            let fadeOut = SKAction.fadeOut(withDuration: 0.3)
            let remove = SKAction.removeFromParent()
            ball.run(SKAction.sequence([fadeOut, remove]))
        }
        balls.removeAll()
    }
    
    // MARK: - Collision Detection
    
    func didBegin(_ contact: SKPhysicsContact) {
        let currentTime = CACurrentMediaTime()
        
        // Throttle haptic feedback to prevent overwhelming
        guard currentTime - lastHapticTime > hapticCooldown else { return }
        
        // Check if either ball has already triggered haptics
        guard let nodeA = contact.bodyA.node,
              let nodeB = contact.bodyB.node else { return }
        
        let ballAId = ObjectIdentifier(nodeA)
        let ballBId = ObjectIdentifier(nodeB)
        
        // Only trigger haptics if at least one ball hasn't triggered haptics yet
        let ballAAlreadyTriggered = ballsWithHaptics.contains(ballAId)
        let ballBAlreadyTriggered = ballsWithHaptics.contains(ballBId)
        
        guard !ballAAlreadyTriggered || !ballBAlreadyTriggered else { return }
        
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask
        let collisionImpulse = contact.collisionImpulse
        var hapticTriggered = false
        
        // Determine haptic intensity based on collision type and impulse
        switch collision {
        case hourBallCategory | hourBallCategory:
            // Hour ball to hour ball collision - heavy feedback
            if collisionImpulse > 5.0 {
                heavyImpact.impactOccurred()
                heavyImpact.prepare()
                hapticTriggered = true
            }
            
        case hourBallCategory | minuteBallCategory,
             minuteBallCategory | hourBallCategory:
            // Hour and minute ball collision - medium feedback
            if collisionImpulse > 3.0 {
                mediumImpact.impactOccurred()
                mediumImpact.prepare()
                hapticTriggered = true
            }
            
        case hourBallCategory | secondBallCategory,
             secondBallCategory | hourBallCategory:
            // Hour and second ball collision - medium feedback
            if collisionImpulse > 2.0 {
                mediumImpact.impactOccurred()
                mediumImpact.prepare()
                hapticTriggered = true
            }
            
        case minuteBallCategory | minuteBallCategory:
            // Minute ball to minute ball collision - medium feedback
            if collisionImpulse > 3.0 {
                mediumImpact.impactOccurred()
                mediumImpact.prepare()
                hapticTriggered = true
            }
            
        case minuteBallCategory | secondBallCategory,
             secondBallCategory | minuteBallCategory:
            // Minute and second ball collision - light feedback
            if collisionImpulse > 1.0 {
                lightImpact.impactOccurred()
                lightImpact.prepare()
                hapticTriggered = true
            }
            
        case secondBallCategory | secondBallCategory:
            // Second ball to second ball collision - light feedback
            if collisionImpulse > 1.0 {
                lightImpact.impactOccurred()
                lightImpact.prepare()
                hapticTriggered = true
            }
            
        case millisecondBallCategory | millisecondBallCategory,
             millisecondBallCategory | secondBallCategory,
             secondBallCategory | millisecondBallCategory,
             millisecondBallCategory | minuteBallCategory,
             minuteBallCategory | millisecondBallCategory,
             millisecondBallCategory | hourBallCategory,
             hourBallCategory | millisecondBallCategory:
            // Millisecond ball collisions - no haptic feedback (too frequent)
            break
            
        case let category where category & boundaryCategory != 0:
            // Ball hitting boundary - feedback based on ball type
            let ballCategory = collision & ~boundaryCategory
            
            if ballCategory == hourBallCategory && collisionImpulse > 8.0 {
                heavyImpact.impactOccurred()
                heavyImpact.prepare()
                hapticTriggered = true
            } else if ballCategory == minuteBallCategory && collisionImpulse > 5.0 {
                mediumImpact.impactOccurred()
                mediumImpact.prepare()
                hapticTriggered = true
            } else if ballCategory == secondBallCategory && collisionImpulse > 3.0 {
                lightImpact.impactOccurred()
                lightImpact.prepare()
                hapticTriggered = true
            } else if ballCategory == millisecondBallCategory && collisionImpulse > 1.0 {
                // No haptic feedback for millisecond balls hitting boundaries (too frequent)
            }
            
        default:
            break
        }
        
        // Update throttle timer and mark balls as having triggered haptics
        if hapticTriggered {
            lastHapticTime = currentTime
            
            // Mark the balls that participated in this collision as having triggered haptics
            if !ballAAlreadyTriggered {
                ballsWithHaptics.insert(ballAId)
            }
            if !ballBAlreadyTriggered {
                ballsWithHaptics.insert(ballBId)
            }
        }
    }
    
    deinit {
        motionManager.stopDeviceMotionUpdates()
    }
}