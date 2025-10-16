//
//  GameScene.swift
//  zero-turn-game
//
//  Created by Joe Pettinelli on 10/13/25.
//
import SpriteKit
import GameplayKit


class GameScene: SKScene {
    
    var entities = [GKEntity]()
    var graphs = [String : GKGraph]()
    
    private var lastUpdateTime : TimeInterval = 0
    private var mowerNode : MowerNode!
    private var cameraNode : SKCameraNode!
    private var landscapeNode: LandscapeNode!
    private var leftHandle : HandleSliderNode!
    private var rightHandle : HandleSliderNode!
    private var handleTouches = [UITouch: HandleSliderNode]()
    
    override func sceneDidLoad() {
        
        self.lastUpdateTime = 0
        
        mowerNode = MowerNode()
        mowerNode.node.position = CGPoint(x: frame.midX, y: frame.midY)
        
        // Add joystick to control movement
        let joystickHeight = self.size.height * 0.1
        leftHandle = HandleSliderNode(height: joystickHeight)
        leftHandle.position = CGPoint(x: frame.minX + 70, y: frame.midY)
        addChild(leftHandle)
        rightHandle = HandleSliderNode(height: joystickHeight)
        rightHandle.position = CGPoint(x: frame.maxX - 50, y: frame.midY)
        addChild(rightHandle)
        
        landscapeNode = LandscapeNode()
        addChild(landscapeNode.node)
        
        cameraNode = SKCameraNode()
        self.camera = cameraNode
        cameraNode.position = mowerNode.node.position
        addChild(cameraNode)
        cameraNode.addChild(mowerNode.node)
        mowerNode.node.position = .zero
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        for t in touches {
            let location = t.location(in: self)
            
            if leftHandle.contains(location) {
                handleTouches[t] = leftHandle
            } else if rightHandle.contains(location) {
                handleTouches[t] = rightHandle
            } else {
                return
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            if let handle = handleTouches[t] {
                let location = t.location(in: handle)
                handle.updateKnobPosition(touchY: location.y)
            } else {
                return
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            if let handle = handleTouches[t] {
                handle.reset()
                handleTouches.removeValue(forKey: t)
                
            } else {
                return
            }
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
    
    override func update(_ currentTime: TimeInterval) -> Void {
        // Called before each frame is rendered
        
        // Initialize lastUpdateTime
        if (self.lastUpdateTime == 0) {
            self.lastUpdateTime = currentTime
        }
        
        // Calculate turnAmount and moveAmount
        let dt = currentTime - self.lastUpdateTime
        let leftPower = leftHandle.value    // -1.0 to 1.0
        let rightPower = rightHandle.value  // -1.0 to 1.0
        let turnAmount = (rightPower - leftPower) * dt
        let moveAmount = (rightPower + leftPower) * dt
        
        // Move landscape node position
        let moveSpeed: CGFloat = 50.0
        let angle: CGFloat = cameraNode.zRotation + (CGFloat.pi / 2)
        let dxDir = -cos(angle)
        let dx = dxDir * moveAmount * moveSpeed
        let dyDir = -sin(angle)
        let dy = dyDir * moveAmount * moveSpeed
        landscapeNode.node.position.x += dx
        landscapeNode.node.position.y += dy
        
        // Rotate landscape node in opposite direction of mower node
        let rotation = -CGFloat(turnAmount)
        let center = mowerNode.node.position
        let currentPos = landscapeNode.node.position
        // Apply affine transforms. Translate -> rotate -> translate back
        var transform = CGAffineTransform(translationX: -center.x, y: -center.y)
        var rotatedPos = currentPos.applying(transform)
        transform = CGAffineTransform(rotationAngle: rotation)
        rotatedPos = rotatedPos.applying(transform)
        transform = CGAffineTransform(translationX: center.x, y: center.y)
        rotatedPos = rotatedPos.applying(transform)
        landscapeNode.node.position = rotatedPos
        landscapeNode.node.zRotation += rotation
        
        // Leave trail mark on landscape node at position of mower node
        let worldPos = convert(mowerNode.node.position, to: landscapeNode.node)
        leaveTrailMark(at: worldPos)
        
        self.lastUpdateTime = currentTime
    }
    
    func leaveTrailMark(at position: CGPoint) -> Void {
        // Leave trail mark behind the mower
        if let mower = mowerNode {
            let radius = mower.node.frame.size.width / 4
            let mark = SKShapeNode(circleOfRadius: radius)
            mark.fillColor = .systemGreen
            mark.strokeColor = .clear
            mark.position = position
            mark.zPosition = -1
            landscapeNode.node.addChild(mark)
        } else { return }
    }

}
