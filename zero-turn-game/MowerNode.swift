//
//  MowerNode.swift
//  zero-turn-game
//
//  Created by Joe Pettinelli on 10/13/25.
//
import SpriteKit


class MowerNode {
    
    let node: SKSpriteNode
    let forwardOffset: CGFloat = CGFloat.pi / 2  // 90 degrees counter-clockwise
    let forwardSpeed: CGFloat = 50.0

    init() {
        
        self.node = SKSpriteNode(imageNamed: "husqvarna")
        self.node.zPosition = 1
    }
    
//    func moveForwardBy(by moveAmount: CGFloat) -> Void {
//        // Move the mower forward
//        let angle = node.zRotation
//        let dirX = cos(angle + forwardOffset)
//        let dirY = sin(angle + forwardOffset)
//        let magnitude = moveAmount * forwardSpeed
//        let dx = dirX * magnitude
//        let dy = dirY * magnitude
//        node.position = CGPoint(x: node.position.x + dx, y: node.position.y + dy)
//    }
//    
//    func rotateBy(by rotateAmount: CGFloat) -> Void {
//        // Rotate the mower
//        node.zRotation += rotateAmount
//        node.zRotation = node.zRotation.truncatingRemainder(dividingBy: CGFloat.pi * 2)
//    }
    
}
