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
    
    var cutRadius: CGFloat {
        return node.frame.width / 4
    }

    init() {
        self.node = SKSpriteNode(imageNamed: "husqvarna")
        self.node.zPosition = zPos
    }
}
