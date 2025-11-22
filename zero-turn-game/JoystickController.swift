//
//  JoystickController.swift
//  zero-turn-game
//
//  Created by Joe Pettinelli on 10/17/25.
//
import UIKit


protocol JoystickDelegate: AnyObject {
    func joystickDidBegin(_ joystick: JoystickView)
    func joystickDidMove(_ joystick: JoystickView, value: CGFloat)
    func joystickDidEnd(_ joystick: JoystickView)
}


class JoystickView: UIView {

    weak var delegate: JoystickDelegate?

    private let knob = UIView()
    private var knobCenter: CGPoint = .zero
    private var isTouchActive = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    /// Setup the joystick view
    private func setup() -> Void {
        // Create rectangular background
        backgroundColor = UIColor.darkGray
        backgroundColor = UIColor.darkGray.withAlphaComponent(0.5)
        layer.cornerRadius = bounds.width / 4
        clipsToBounds = true
        // Create knob for user touch
        let knobDiameter = bounds.width * 0.9
        knob.frame = CGRect(x: 0, y: 0, width: knobDiameter, height: knobDiameter)
        knob.layer.cornerRadius = knobDiameter / 2
        knob.backgroundColor = .white
        knobCenter = CGPoint(x: bounds.midX, y: bounds.midY)
        knob.center = knobCenter
        knob.backgroundColor = UIColor.white.withAlphaComponent(0.7)
        addSubview(knob)
        isUserInteractionEnabled = true
    }
    
    /// Update the knob after user touch. UIKit coordinate
    /// system Y-axis increases downward.
    ///
    /// - Parameters:
    ///     - touch: User touch on knob
    private func updateKnob(with touch: UITouch) -> Void {
        let touchY = touch.location(in: self).y
        let maxOffsetY = (bounds.height / 2) - knob.frame.height / 2
        let dy = touchY - knobCenter.y
        let clampedDY = max(-maxOffsetY, min(maxOffsetY, dy))
        knob.center = CGPoint(x: knobCenter.x, y: knobCenter.y + clampedDY)
        let normY = clampedDY / maxOffsetY
        delegate?.joystickDidMove(self, value: -normY)
    }
    
    /// Reset the knob to zero position
    private func resetKnob() -> Void {
        UIView.animate(withDuration: 0.2) {
            self.knob.center = self.knobCenter
        }
        delegate?.joystickDidEnd(self)
        isTouchActive = false
    }
    
    /// Handle when joystick touches began
    ///
    /// - Parameters:
    ///     - touches: Joystick touches
    ///     - event: UIEvent
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) -> Void {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)
        let dx = location.x - knob.center.x
        let dy = location.y - knob.center.y
        let distance = sqrt(dx * dx + dy * dy)
        // Only continue if touch is inside the joystick knob
        guard distance <= knob.bounds.width / 2 else {
            isTouchActive = false
            return
        }
        isTouchActive = true
        updateKnob(with: touch)
        delegate?.joystickDidBegin(self)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) -> Void {
        guard isTouchActive, let touch = touches.first else { return }
        updateKnob(with: touch)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) -> Void {
        guard isTouchActive else { return }
        resetKnob()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) -> Void {
        guard isTouchActive else { return }
        resetKnob()
    }
}
