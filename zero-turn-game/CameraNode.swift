//
//  CameraNode.swift
//  zero-turn-game
//
//  Created by Joe Pettinelli on 10/17/25.
//
import SpriteKit


enum CameraMode {
    case centerOnMower
    case centerOnLandscape
}


class CameraNode {
    
    let node: SKCameraNode = SKCameraNode()
    var cameraMode: CameraMode = .centerOnLandscape
    
    /// Switch the camera mode. Either have camera follow
    /// the mower or have it zoom out to show full landscape
    func switchCameraMode() -> Void {
        switch cameraMode {
        case .centerOnMower:
            cameraMode = .centerOnLandscape
        case .centerOnLandscape:
            cameraMode = .centerOnMower
        }
    }
}
