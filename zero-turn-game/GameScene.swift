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
    private var landscapeNode: LandscapeNode!
    var cameraNode : CameraNode!
    var leftHandleValue: CGFloat = 0.0
    var rightHandleValue: CGFloat = 0.0
    
    /// Add scene components when the scene first loads
    override func sceneDidLoad() -> Void {
        // Add mower to control
        mowerNode = MowerNode()
        mowerNode.node.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(mowerNode.node)
        // Add landscape node which includes grass, trail marks, etc.
        landscapeNode = LandscapeNode(grassImage: "grass3", dirtImage: "background")
        addChild(landscapeNode.node)
        // Add camera node
        cameraNode = CameraNode()
        cameraNode.node.position = landscapeNode.originalCenter
        addChild(cameraNode.node)
        self.camera = cameraNode.node
    }
    
    /// Update the scene before it is rendered
    ///
    /// - Parameters:
    ///     - currentTime: The time to set as last updated time
    override func update(_ currentTime: TimeInterval) -> Void {
        if (self.lastUpdateTime == 0) {
            self.lastUpdateTime = currentTime
        }
        // Calculate turnAmount and moveAmount
        // Handle values in range -1.0 to 1.0
        let dt = currentTime - self.lastUpdateTime
        let leftPower = leftHandleValue
        let rightPower = rightHandleValue
        let turnAmount = (rightPower - leftPower) * dt
        let moveAmount = (rightPower + leftPower) * dt
        landscapeNode.moveAndRotate(
            moveAmount: moveAmount,
            turnAmount: turnAmount,
            center: mowerNode.node.position,
            cameraRotation: cameraNode.node.zRotation,
            in: self
        )
        // Leave trail mark only if mower is moving
        if moveAmount != 0.0 {
            let worldPos = self.convert(mowerNode.node.position, to: landscapeNode.node)
            landscapeNode.cutGrass(at: worldPos, radius: mowerNode.cutRadius)
        }
        // Position camera depending on CameraMode flag
        if cameraNode.cameraMode == .centerOnMower {
            centerCameraOnMower()
        } else { centerCameraOnLandscape() }
        self.lastUpdateTime = currentTime
    }
    
    /// Center the camera on the center of landscape
    func centerCameraOnLandscape() -> Void {
        let centerInLandscape = landscapeNode.originalCenter
        let centerInScene = landscapeNode.node.convert(centerInLandscape, to: self)
        let moveAction = SKAction.move(to: centerInScene, duration: 0.2)
        let zoomAction = SKAction.scale(to: 2.0, duration: 0.2)
        moveAction.timingMode = .easeInEaseOut
        zoomAction.timingMode = .easeInEaseOut
        let actionGroup = SKAction.group([moveAction, zoomAction])
        cameraNode.node.run(actionGroup)
    }
    
    /// Center the camera on the mower
    func centerCameraOnMower() -> Void {
        let targetPosition = mowerNode.node.position
        let moveAction = SKAction.move(to: targetPosition, duration: 0.1)
        let zoomAction = SKAction.scale(to: 0.80, duration: 0.1)
        moveAction.timingMode = .easeInEaseOut
        zoomAction.timingMode = .easeInEaseOut
        let actionGroup = SKAction.group([moveAction, zoomAction])
        cameraNode.node.run(actionGroup)
    }
}
