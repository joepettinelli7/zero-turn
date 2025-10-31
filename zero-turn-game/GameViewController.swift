//
//  GameViewController.swift
//  zero-turn-game
//
//  Created by Joe Pettinelli on 10/13/25.
//
import UIKit
import SpriteKit
import GameplayKit


class GameViewController: UIViewController, JoystickDelegate {
    
    private var leftJoystick: JoystickView!
    private var rightJoystick: JoystickView!
    private var gameScene: GameScene?
    private var timerLabel: UILabel!
    private var timer: Timer?
    private var elapsedTime: Double = 0.0
    
    override func viewDidLoad() -> Void {
        super.viewDidLoad()
        // Load 'GameScene.sks' as a GKScene. This provides gameplay related content
        // including entities and graphs.
        if let scene = GKScene(fileNamed: "GameScene") {
            // Get the SKScene from the loaded GKScene
            if let sceneNode = scene.rootNode as! GameScene? {
                // Copy gameplay related content over to the scene
                sceneNode.entities = scene.entities
                sceneNode.graphs = scene.graphs
                // Set the scale mode to scale to fit the window
                sceneNode.scaleMode = .aspectFill
                // Present the scene
                if let view = self.view as! SKView? {
                    view.presentScene(sceneNode)
                    view.ignoresSiblingOrder = true
                    view.showsFPS = true
                    view.showsNodeCount = true
                    self.gameScene = sceneNode
                }
            }
            addJoysticks(to: self.view)
            setupTimerLabel()
            startTimer()
        }
    }
    
    /// Add joysticks to GameViewController view
    ///
    /// - Parameters:
    ///     - view: The GameViewController view
    private func addJoysticks(to view: UIView) -> Void {
        let joystickSize = CGSize(width: 80, height: 220)
        leftJoystick = createJoystick(size: joystickSize)
        rightJoystick = createJoystick(size: joystickSize)
        view.addSubview(leftJoystick)
        view.addSubview(rightJoystick)

        NSLayoutConstraint.activate([
            // Left joystick bottom-left
            leftJoystick.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            leftJoystick.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -40),
            leftJoystick.widthAnchor.constraint(equalToConstant: joystickSize.width),
            leftJoystick.heightAnchor.constraint(equalToConstant: joystickSize.height),
            // Right joystick bottom-right
            rightJoystick.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            rightJoystick.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -40),
            rightJoystick.widthAnchor.constraint(equalToConstant: joystickSize.width),
            rightJoystick.heightAnchor.constraint(equalToConstant: joystickSize.height),
        ])
    }
    
    /// Create a joystick view
    ///
    /// - Parameters
    ///     - size: Size of joystick
    /// - Returns:
    ///     - The joystick view
    func createJoystick(size: CGSize) -> JoystickView {
        let joystick = JoystickView(frame: CGRect(origin: .zero, size: size))
        joystick.delegate = self
        joystick.translatesAutoresizingMaskIntoConstraints = false
        return joystick
    }
    
    /// Must have this function to conform to Joystick delegate
    ///
    /// - Parameters:
    ///     - joystick: The joystick that moved
    func joystickDidBegin(_ joystick: JoystickView) -> Void {
        if joystick == leftJoystick || joystick == rightJoystick {
            if gameScene?.cameraNode.cameraMode == .centerOnLandscape {
                gameScene?.cameraNode.switchCameraMode()
            }
        }
    }
    
    /// Must have this function to conform to Joystick delegate
    ///
    /// - Parameters:
    ///     - joystick: The joystick view that moved
    ///     - value: The normalized value of joystick y position
    func joystickDidMove(_ joystick: JoystickView, value: CGFloat) -> Void {
        if joystick == leftJoystick {
            gameScene?.leftHandleValue = value
        } else if joystick == rightJoystick {
            gameScene?.rightHandleValue = value
        }
    }
    
    /// Must have this function to conform to Joystick delegate
    ///
    /// - Parameters:
    ///     - joystick: The joystick view that was released
    func joystickDidEnd(_ joystick: JoystickView) -> Void {
        if joystick == leftJoystick {
            gameScene?.leftHandleValue = 0
        } else if joystick == rightJoystick {
            gameScene?.rightHandleValue = 0
        }
        // Check if both are released to trigger zoom out
        if gameScene?.leftHandleValue == 0 && gameScene?.rightHandleValue == 0 {
            if gameScene?.cameraNode.cameraMode == .centerOnMower {
                gameScene?.cameraNode.switchCameraMode()
                gameScene?.centerCameraOnLandscape()
            }
        }
    }
    
    /// Setup timer label that counts mowing time
    private func setupTimerLabel() -> Void {
        timerLabel = UILabel()
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        timerLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 24, weight: .bold)
        timerLabel.textColor = .white
        timerLabel.textAlignment = .center
        timerLabel.text = "Time: 0.0s"
        view.addSubview(timerLabel)
        
        NSLayoutConstraint.activate([
            timerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            timerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
    }
    
    /// Start the timer to count mowing time
    private func startTimer() -> Void {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if self.gameScene?.cameraNode.cameraMode == .centerOnMower {
                self.elapsedTime += 0.1
                self.timerLabel.text = String(format: "Time: %.1f s", self.elapsedTime)
            }
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
