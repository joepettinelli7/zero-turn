//
//  HandleSliderNode.swift
//  zero-turn-game
//
//  Created by Joe Pettinelli on 10/13/25.
//
import SpriteKit


class HandleSliderNode: SKNode {
    
    private let track: SKShapeNode
    private let knob: SKShapeNode
    private let height: CGFloat
    private(set) var value: CGFloat = 0.0  // -1.0 to 1.0

    init(height: CGFloat = 100, width: CGFloat = 40) {
        self.height = height
        // Track (background)
        let trackRect = CGRect(x: -width / 2, y: -height / 2, width: width, height: height)
        track = SKShapeNode(rect: trackRect, cornerRadius: width / 4)
        track.fillColor = .darkGray
        track.strokeColor = .clear

        // Knob (movable part)
        let knobSize = CGSize(width: width * 0.9, height: width * 0.9)
        knob = SKShapeNode(rectOf: knobSize, cornerRadius: width * 0.45)
        knob.fillColor = .white
        knob.strokeColor = .gray
        knob.position = CGPoint(x: 0, y: 0)

        super.init()
        self.isUserInteractionEnabled = false  // Touches handled by GameScene
        addChild(track)
        addChild(knob)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateKnobPosition(touchY: CGFloat) {
        // Clamp Y position
        let clampedY = max(-height / 2, min(height / 2, touchY))
        knob.position.y = clampedY
        // Normalize to range [-1, 1]
        value = clampedY / (height / 2)
    }
    
    func reset() {
        knob.position.y = 0
        value = 0
    }
}
