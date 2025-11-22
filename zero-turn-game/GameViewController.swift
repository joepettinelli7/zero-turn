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
    private var resetButton: UIButton!
    private var playAgainButton: UIButton!
    private var inGameEnd: Bool = false
    
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
            addResetButton(to: self.view, above: redMaskButton)
            addPlayAgainButton(to: self.view)
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
                    self.updateProgressBar(coverage, should_animate: 1.0)
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
        gameScene?.playButtonClickAudio()
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
    ///     - should_animate: 0.0 if progress bar should be reset without animation
    private func updateProgressBar(_ coverage: CGFloat, should_animate: Double) -> Void {
        let clamped = max(0, min(1, coverage))
        let barHeight = progressContainer.bounds.height * clamped
        progressFillHeightConstraint.constant = barHeight
        UIView.animate(withDuration: 0.15 * should_animate) {
            self.progressContainer.layoutIfNeeded()
            // Color gradient: red to yellow to green
            self.progressFill.backgroundColor = UIColor(
                hue: clamped * 0.33,
                saturation: 1.0,
                brightness: 1.0,
                alpha: 1.0
            )
            self.progressLabel.text = String(format: "%.0f%%", floor(clamped * 100))
        }
        if coverage == 1.0 {
            onGameEnd()
        }
    }
    
    /// Call this function when the game ends
    private func onGameEnd() -> Void {
        inGameEnd = true
        gameScene?.onGameEnd()
        redMaskButton.isEnabled = false
        redMaskButton.isHidden = true
        leftJoystick.isUserInteractionEnabled = false
        leftJoystick.isHidden = true
        rightJoystick.isUserInteractionEnabled = false
        rightJoystick.isHidden = true
        progressContainer.isHidden = true
        progressFill.isHidden = true
        progressLabel.isHidden = true
        transformTimerLabelOnGameEnd()
        resetButton.isHidden = true
        resetButton.isUserInteractionEnabled = false
        playAgainButton.isHidden = false
    }
    
    /// Transform the timer label on game end to move to center
    /// of the screen and become larger font size.
    private func transformTimerLabelOnGameEnd() -> Void {
        guard let view = timerLabel.superview else { return }
        timerLabel.layer.removeAllAnimations()
        view.removeConstraints(view.constraints.filter {
            $0.firstItem as? UILabel == timerLabel || $0.secondItem as? UILabel == timerLabel
        })
        NSLayoutConstraint.activate([
            timerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            timerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 60)
        ])
        // Animate placement
        UIView.animate(withDuration: 2.0,
                       delay: 0,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 0.4,
                       options: [.curveEaseInOut],
                       animations: {
            view.layoutIfNeeded()
            self.timerLabel.transform = CGAffineTransform(scaleX: 2.0, y: 2.0)
        })
        // Animate blink
        UIView.animate(withDuration: 0.5,
                       delay: 0.0,
                       options: [.autoreverse, .repeat, .allowUserInteraction],
                       animations: {
            self.timerLabel.alpha = 0.1
        })
    }
    
    /// Add the play again button, and hide is by default until game ends
    func addPlayAgainButton(to view: UIView) -> Void {
        playAgainButton = UIButton(type: .system)
        playAgainButton.translatesAutoresizingMaskIntoConstraints = false
        playAgainButton.isHidden = true
        var config = UIButton.Configuration.filled()
        config.baseBackgroundColor = UIColor.darkGray
        config.baseForegroundColor = .white
        config.contentInsets = NSDirectionalEdgeInsets(top: 14, leading: 20, bottom: 14, trailing: 20)
        let font = UIFont.systemFont(ofSize: 48, weight: .black)
        config.attributedTitle = AttributedString("Play Again", attributes: AttributeContainer([.font: font]))
        playAgainButton.configuration = config
        playAgainButton.addTarget(self, action: #selector(resetButtonTapped), for: .touchUpInside)
        view.addSubview(playAgainButton)
        NSLayoutConstraint.activate([
            playAgainButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            playAgainButton.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -100),
            playAgainButton.widthAnchor.constraint(equalToConstant: 300),
            playAgainButton.heightAnchor.constraint(equalToConstant: 100)
        ])
    }
    
    /// Add button to reset mowing session
    private func addResetButton(to view: UIView, above leftJoystick: UIButton) -> Void {
        resetButton = UIButton(type: .system)
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        resetButton.layer.cornerRadius = 8
        resetButton.clipsToBounds = true
        // Use configuration
        var config = UIButton.Configuration.filled()
        config.image = UIImage(systemName: "arrow.counterclockwise")
        config.baseBackgroundColor = UIColor.black.withAlphaComponent(0.5)
        config.baseForegroundColor = .systemBlue
        resetButton.configuration = config
        // Add target
        resetButton.addTarget(self, action: #selector(resetButtonTapped), for: .touchUpInside)
        view.addSubview(resetButton)
        NSLayoutConstraint.activate([
            resetButton.bottomAnchor.constraint(equalTo: redMaskButton.topAnchor, constant: -10),
            resetButton.centerXAnchor.constraint(equalTo: redMaskButton.centerXAnchor),
            resetButton.widthAnchor.constraint(equalTo: redMaskButton.widthAnchor),
            resetButton.heightAnchor.constraint(equalTo: redMaskButton.heightAnchor)
        ])
    }
    
    /// Reset the mowing session and view
    @objc private func resetButtonTapped() -> Void {
        gameScene?.playButtonClickAudio()
        gameScene?.onReset()
        timerLabel.text = "Time: 0.0s"
        elapsedTime = 0.0
        redMaskButton.isEnabled = true
        redMaskButton.isHidden = false
        leftJoystick.isUserInteractionEnabled = true
        leftJoystick.isHidden = false
        rightJoystick.isUserInteractionEnabled = true
        rightJoystick.isHidden = false
        let should_animate = inGameEnd ? 0.0 : 1.0
        updateProgressBar(0.0, should_animate: should_animate)
        progressContainer.isHidden = false
        progressFill.isHidden = false
        progressLabel.isHidden = false
        undoTimerLabelTransform()
        resetButton.isHidden = false
        resetButton.isUserInteractionEnabled = true
        playAgainButton.isHidden = true
        inGameEnd = false
    }
    
    /// When Play Again button is pressed after game ends return the
    /// timer label to the original position at the top center of screen
    private func undoTimerLabelTransform() -> Void {
        timerLabel.layer.removeAllAnimations()
        timerLabel.transform = .identity
        timerLabel.alpha = 1.0
        if let view = timerLabel.superview {
            view.removeConstraints(view.constraints.filter {
                $0.firstItem as? UILabel == timerLabel || $0.secondItem as? UILabel == timerLabel
            })
        }
        NSLayoutConstraint.activate([
            timerLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            timerLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])
        UIView.animate(withDuration: 0.5) {
            self.timerLabel.superview?.layoutIfNeeded()
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
