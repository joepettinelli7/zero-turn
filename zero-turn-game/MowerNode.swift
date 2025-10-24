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
    let bladeOffset: CGPoint = CGPoint(x: -13, y: 25)
    
    var cutRadius: CGFloat {
        return node.frame.width / 3.5
    }

    init() {
        node = SKSpriteNode(imageNamed: "husqvarna")
        node.zPosition = zPos
        node.physicsBody = SKPhysicsBody(circleOfRadius: node.frame.width / 2)
        node.physicsBody?.isDynamic = true
        node.physicsBody?.affectedByGravity = false
        node.physicsBody?.categoryBitMask = PhysicsCategory.mower
        node.physicsBody?.collisionBitMask = PhysicsCategory.obstacle
        node.physicsBody?.contactTestBitMask = PhysicsCategory.obstacle
    }
}
