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

    init() {
        node = SKSpriteNode(imageNamed: "husqvarna")
        node.zPosition = zPos
        node.physicsBody = SKPhysicsBody(circleOfRadius: node.frame.width / 2)
        node.physicsBody?.isDynamic = true
        node.physicsBody?.affectedByGravity = false
        node.physicsBody?.categoryBitMask = PhysicsCategory.mower
        node.physicsBody?.collisionBitMask = PhysicsCategory.obstacle
        node.physicsBody?.contactTestBitMask = PhysicsCategory.obstacle
        grassEmitter = Self.makeGrassEmitter()
        grassEmitter.position = CGPoint(x: node.size.width / 2, y: bladeOffset.y)
        grassEmitter.zPosition = -1
        node.addChild(grassEmitter)
        cutWidth = node.frame.width / 1.35
        cutHeight = node.frame.height / 2.99
    }
    
    /// Make the emitter for cut grass blades coming out of chute
    ///
    /// - Returns:
    ///     - The emitter
    private static func makeGrassEmitter() -> SKEmitterNode {
        let emitter = SKEmitterNode()
        // Appearance
        emitter.particleTexture = nil
        emitter.particleColor = UIColor(red: 1.0, green: 0, blue: 0, alpha: 1.0)
        emitter.particleColorBlendFactor = 1.0
        emitter.particleSize = CGSize(width: 10, height: 10)
        emitter.particlePositionRange = CGVector(dx: 10, dy: 40)
        // Emission
        emitter.particleBirthRate = 200
        emitter.particleLifetime = 0.5
        emitter.emissionAngle = -0.54
        emitter.emissionAngleRange = 0.20
        emitter.particleSpeed = 500
        emitter.particleSpeedRange = 10
        // Fade and behavior
        emitter.particleAlpha = 0.8
        emitter.particleAlphaSpeed = -5.0
        emitter.particleScale = 0.5
        emitter.particleScaleSpeed = -0.5
        emitter.particleBlendMode = .alpha
        emitter.targetNode = nil
        return emitter
    }
}
