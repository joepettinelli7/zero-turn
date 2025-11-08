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
    private var redMaskButton: UIButton!
    private var redMaskIsHidden: Bool = false
    private var progressContainer: UIView!
    private var progressFill: UIView!
    private var progressLabel: UILabel!
    private var progressFillHeightConstraint: NSLayoutConstraint!
    
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
            addTimerLabel(to: self.view)
            startTimer()
            addToggleMaskButton(to: self.view, above: rightJoystick)
            addProgressBar(to: self.view, above: leftJoystick)
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
    ///
    /// - Parameters:
    ///     - view: The view to add the timer label to
    private func addTimerLabel(to view: UIView) -> Void {
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
                if let coverage = self.gameScene?.totalCutCoverage {
                    self.updateProgressBar(coverage)
                }
            }
        }
    }
    
    /// Add a button to toggle the debug mask visibility
    ///
    /// - Parameters:
    ///     - The view to add button to
    ///     - The right joystick to control mower
    private func addToggleMaskButton(to view: UIView, above rightJoystick: UIView) -> Void {
        redMaskButton = UIButton(type: .system)
        redMaskButton.translatesAutoresizingMaskIntoConstraints = false
        redMaskButton.setImage(UIImage(systemName: "eye"), for: .normal)
        redMaskButton.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        redMaskButton.layer.cornerRadius = 8
        redMaskButton.addTarget(self, action: #selector(redMaskButtonTapped), for: .touchUpInside)
        view.addSubview(redMaskButton)
        NSLayoutConstraint.activate([
            redMaskButton.bottomAnchor.constraint(equalTo: rightJoystick.topAnchor, constant: -10),
            redMaskButton.centerXAnchor.constraint(equalTo: rightJoystick.centerXAnchor),
            redMaskButton.widthAnchor.constraint(equalToConstant: 60),
            redMaskButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }
    
    /// Call the function in game scene to toggle mask. Switch button image based on state.
    @objc private func redMaskButtonTapped() -> Void {
        gameScene?.toggleRedMaskHidden()
        redMaskIsHidden = !redMaskIsHidden
        let imageName = redMaskIsHidden ? "eye.slash" : "eye"
        redMaskButton.setImage(UIImage(systemName: imageName), for: .normal)
    }
    
    /// Add a vertical progress bar on the left side of the screen
    ///
    /// - Parameters:
    ///     - view: The view to add progress bar to
    ///     - leftJoystick: Left joystick to control mower
    private func addProgressBar(to view: UIView, above leftJoystick: UIView) -> Void {
        let barWidth: CGFloat = 24
        let barHeight: CGFloat = view.bounds.height * 0.5
        // Background container
        progressContainer = UIView()
        progressContainer.translatesAutoresizingMaskIntoConstraints = false
        progressContainer.backgroundColor = UIColor(white: 0.2, alpha: 0.6)
        progressContainer.layer.cornerRadius = 6
        progressContainer.clipsToBounds = true
        view.addSubview(progressContainer)
        // Fill view
        progressFill = UIView()
        progressFill.translatesAutoresizingMaskIntoConstraints = false
        progressFill.backgroundColor = .systemGreen
        progressContainer.addSubview(progressFill)
        // Label for %
        progressLabel = UILabel()
        progressLabel.translatesAutoresizingMaskIntoConstraints = false
        progressLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 14, weight: .bold)
        progressLabel.textColor = .white
        progressLabel.textAlignment = .center
        progressLabel.text = "0%"
        progressFillHeightConstraint = progressFill.heightAnchor.constraint(equalToConstant: 0)
        progressFillHeightConstraint.isActive = true
        view.addSubview(progressLabel)
        // Layout constraints
        NSLayoutConstraint.activate([
            progressContainer.bottomAnchor.constraint(equalTo: leftJoystick.topAnchor, constant: -10),
            progressContainer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            progressContainer.widthAnchor.constraint(equalToConstant: barWidth),
            progressContainer.heightAnchor.constraint(equalToConstant: barHeight),
            progressFill.bottomAnchor.constraint(equalTo: progressContainer.bottomAnchor),
            progressFill.leadingAnchor.constraint(equalTo: progressContainer.leadingAnchor),
            progressFill.trailingAnchor.constraint(equalTo: progressContainer.trailingAnchor),
            progressLabel.centerXAnchor.constraint(equalTo: progressContainer.centerXAnchor),
            progressLabel.bottomAnchor.constraint(equalTo: progressContainer.topAnchor, constant: -8)
        ])
    }
    
    /// Update vertical progress bar fill based on coverage (0.0–1.0).
    ///
    /// - Parameters:
    ///     - coverage: The total grass cut coverage
    private func updateProgressBar(_ coverage: CGFloat) -> Void {
        let clamped = max(0, min(1, coverage))
        let barHeight = progressContainer.bounds.height * clamped
        progressFillHeightConstraint.constant = barHeight
        UIView.animate(withDuration: 0.15) {
            self.progressContainer.layoutIfNeeded()
            // Color gradient: red to yellow to green
            self.progressFill.backgroundColor = UIColor(
                hue: clamped * 0.33,
                saturation: 1.0,
                brightness: 1.0,
                alpha: 1.0
            )
            self.progressLabel.text = String(format: "%.0f%%", clamped * 100)
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
