//
//  GameScene.swift
//  zero-turn-game
//
//  Created by Joe Pettinelli on 10/13/25.
//
import SpriteKit
import GameplayKit


struct PhysicsCategory {
    static let none: UInt32 = 0
    static let mower: UInt32 = 0b1
    static let obstacle: UInt32 = 0b10
}


class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var entities = [GKEntity]()
    var graphs = [String : GKGraph]()
    
    private var lastUpdateTime: TimeInterval = 0
    private var mowerNode : MowerNode!
    private var landscapeNode: LandscapeNode!
    var cameraNode: CameraNode!
    var leftHandleValue: CGFloat = 0.0
    var rightHandleValue: CGFloat = 0.0
    private var mowerAudioPlayer = MowerAudioPlayer()
    private let flattenEvery: Int = 50
    
    var totalCutCoverage: CGFloat {
        return landscapeNode.totalCutCoverage
    }
    
    /// Add scene components when the scene first loads
    override func sceneDidLoad() -> Void {
        // Add mower to control
        mowerNode = MowerNode()
        mowerNode.node.position = CGPoint(x: frame.midX, y: frame.midY)
        addChild(mowerNode.node)
        // Add landscape node which includes grass, trail marks, etc.
        landscapeNode = LandscapeNode(grassImage: "grass_long", shortGrassImage: "grass_short")
        landscapeNode.addObstacles(count: 2, mowerWidth: mowerNode.node.size.width)
        addChild(landscapeNode.node)
        // Add camera node
        cameraNode = CameraNode()
        cameraNode.node.position = landscapeNode.originalCenter
        addChild(cameraNode.node)
        centerCameraOnLandscape()
        // Add physics
        self.camera = cameraNode.node
        physicsWorld.contactDelegate = self
        // Play mower base blade sound
        mowerAudioPlayer.playAudio()
    }
    
    /// Update the scene before it is rendered. This
    /// function heavily dictates FPS.
    ///
    /// - Parameters:
    ///     - currentTime: The time to set as last updated time
    override func update(_ currentTime: TimeInterval) -> Void {
        if self.lastUpdateTime == 0 { self.lastUpdateTime = currentTime }
        let dt = currentTime - self.lastUpdateTime
        // If camera is centered on landscape, it means mower is idle
        if cameraNode.cameraMode == .centerOnLandscape {
            updateForIdle()
        } else {
            updateForMotion(dt: dt)
        }
        self.lastUpdateTime = currentTime
    }
    
    /// Update mower when it is idle
    func updateForIdle() -> Void {
        mowerNode.grassEmitter.particleBirthRate = 0
        mowerAudioPlayer.setVolume(mowerSpeed: 0.2)
        if landscapeNode.cutCount != 1 {
            landscapeNode.flattenMask(using: self.view!)
        }
    }
    
    /// Update for motion
    ///
    /// - Parameters:
    ///     - dt: Time since last update
    func updateForMotion(dt: CGFloat) -> Void {
        centerCameraOnMower()
        let leftPower = leftHandleValue
        let rightPower = rightHandleValue
        let turnAmount = (rightPower - leftPower) * dt
        let moveAmount = (rightPower + leftPower) * dt
        if moveAmount != 0.0 || turnAmount != 0.0 {
            landscapeNode.moveAndRotate(
                moveAmount: moveAmount,
                turnAmount: turnAmount,
                center: mowerNode.node.position,
                cameraRotation: cameraNode.node.zRotation,
                in: self)
            let bladeLandscapePos = getBladePos()
            let cov = landscapeNode.getMowerCutCoverage(using: self.view!,
                                                        at: bladeLandscapePos,
                                                        mowerNode.cutWidth,
                                                        mowerNode.cutHeight)
            mowerNode.setEmitterBirthRate(cutCoverage: cov)
            let speed = abs(leftPower + rightPower) * 0.5
            mowerAudioPlayer.setVolume(mowerSpeed: speed)
            if cov > 0.0 {
                landscapeNode.cutGrass(at: bladeLandscapePos,
                                       mowerNode.cutWidth,
                                       mowerNode.cutHeight)
            }
            if landscapeNode.cutCount >= flattenEvery {
                landscapeNode.flattenMask(using: self.view!)
            }
        }
    }
    
    /// Get the offset position for the mower blade due to mower image not being symmetrical
    ///
    /// - Returns:
    ///     - The blade position in landscape coordinates
    func getBladePos() -> CGPoint {
        var landscapePos = self.convert(mowerNode.node.position, to: landscapeNode.node)
        let angle = -landscapeNode.node.zRotation
        let rotatedX = mowerNode.bladeOffset.x * cos(angle) - mowerNode.bladeOffset.y * sin(angle)
        let rotatedY = mowerNode.bladeOffset.x * sin(angle) + mowerNode.bladeOffset.y * cos(angle)
        landscapePos.x += rotatedX
        landscapePos.y += rotatedY
        return landscapePos
    }
    
    /// Center the camera on the center of landscape
    func centerCameraOnLandscape() -> Void {
        assert(cameraNode.cameraMode == .centerOnLandscape)
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
        assert(cameraNode.cameraMode == .centerOnMower)
        let targetPosition = mowerNode.node.position
        let moveAction = SKAction.move(to: targetPosition, duration: 0.1)
        let zoomAction = SKAction.scale(to: 0.80, duration: 0.1)
        moveAction.timingMode = .easeInEaseOut
        zoomAction.timingMode = .easeInEaseOut
        let actionGroup = SKAction.group([moveAction, zoomAction])
        cameraNode.node.run(actionGroup)
    }
    
    /// Toggle the red mask visibility
    func toggleRedMaskHidden() -> Void {
        landscapeNode.toggleRedMaskHidden()
    }
    
    /// Remove red mask, zoom out camera, rotate camera to align with landscape, stop audio
    func onGameEnd() {
        landscapeNode.setRedMaskHidden(true)
        cameraNode.cameraMode = .centerOnLandscape
        let targetPosition = landscapeNode.node.convert(landscapeNode.originalCenter, to: self)
        let moveAction = SKAction.move(to: targetPosition, duration: 2.0)
        let rotateAction = SKAction.rotate(toAngle: landscapeNode.node.zRotation, duration: 2.0)
        let zoomAction = SKAction.scale(to: 2.0, duration: 2.0)
        moveAction.timingMode = .easeInEaseOut
        rotateAction.timingMode = .easeInEaseOut
        zoomAction.timingMode = .easeInEaseOut
        let actionGroup = SKAction.group([moveAction, rotateAction, zoomAction])
        cameraNode.node.run(actionGroup)
        mowerAudioPlayer.graduallyStopAudio(fadeDuration: 2.0)
    }
}
