//
//  MowerNode.swift
//  zero-turn-game
//
//  Created by Joe Pettinelli on 10/13/25.
//
import SpriteKit


class MowerNode {
    
    let node: SKSpriteNode
    let zPos: CGFloat = 3.0
    let grassEmitter: SKEmitterNode
    let bladeOffset: CGPoint = CGPoint(x: -13, y: 30)
    let cutWidth: CGFloat
    let cutHeight: CGFloat
    let maxEmitterBirthRate: CGFloat = 200.0
    let maxEmitterSpeed: CGFloat = 500.0

    init() {
        node = SKSpriteNode(imageNamed: "husqvarna")
        node.zPosition = zPos
        node.physicsBody = SKPhysicsBody(circleOfRadius: node.frame.width / 2)
        node.physicsBody?.isDynamic = true
        node.physicsBody?.affectedByGravity = false
        node.physicsBody?.categoryBitMask = PhysicsCategory.mower
        node.physicsBody?.collisionBitMask = PhysicsCategory.obstacle
        node.physicsBody?.contactTestBitMask = PhysicsCategory.obstacle
        cutWidth = node.frame.width / 1.35
        cutHeight = node.frame.height / 2.99
        grassEmitter = SKEmitterNode()
        setEmitterInitials()
        grassEmitter.position = CGPoint(x: node.size.width / 2, y: bladeOffset.y)
        grassEmitter.zPosition = -1
        node.addChild(grassEmitter)
    }
    
    /// Make the emitter for cut grass blades coming out of chute
    private func setEmitterInitials() -> Void {
        // Appearance
        grassEmitter.particleTexture = nil
        grassEmitter.particleColor = UIColor(red: 0, green: 0.85, blue: 0, alpha: 1.0)
        grassEmitter.particleColorBlendFactor = 1.0
        grassEmitter.particleSize = CGSize(width: 10, height: 10)
        grassEmitter.particlePositionRange = CGVector(dx: 10, dy: 35)
        // Emission
        grassEmitter.particleBirthRate = 0.0
        grassEmitter.particleLifetime = 0.5
        grassEmitter.emissionAngle = -0.54
        grassEmitter.emissionAngleRange = 0.20
        grassEmitter.particleSpeed = 0.0
        grassEmitter.particleSpeedRange = 10
        // Fade and behavior
        grassEmitter.particleAlpha = 0.8
        grassEmitter.particleAlphaSpeed = -5.0
        grassEmitter.particleScale = 0.5
        grassEmitter.particleScaleSpeed = -0.5
        grassEmitter.particleBlendMode = .alpha
        grassEmitter.targetNode = nil
    }
    
    /// Set emitter particle birth rate depending on mower speed
    ///
    /// - Parameters:
    ///     - mowerSpeed: New mower speed 0-1
    func setEmitterBirthRate(mowerSpeed: CGFloat) -> Void {
        grassEmitter.particleBirthRate = maxEmitterBirthRate * mowerSpeed
    }
    
    /// Set emitter particle speed depending on mower speed
    ///
    /// - Parameters:
    ///     - mowerSpeed: New mower  speed 0-1
    func setEmitterSpeed(mowerSpeed: CGFloat) -> Void {
        grassEmitter.particleSpeed = maxEmitterSpeed * mowerSpeed
    }
}
