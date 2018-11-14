//
//  AnalogJoystick.swift
//  ACR
//
//  Created by Klemenz, Oliver on 08.12.17.
//  Copyright © 2017 Oliver Klemenz. All rights reserved.
//

import UIKit
import Foundation

public enum AnalogJoystickDirection: String {
    case both = "both"
    case horizontal = "horizontal"
    case vertical = "vertical"
}

@objc public enum AnalogJoystickMode: Int {
    case began
    case move
    case end
}

@objc
protocol AnalogJoystickDelegate {
    func analogJoystickDidChange(_ analogJoystick: AnalogJoystick, position: CGPoint, angle: CGFloat, mode: AnalogJoystickMode)
}

@IBDesignable
public class AnalogJoystick : UIView {
    
    var position: CGPoint = .zero
    var normPosition: CGPoint = .zero
    var angle: CGFloat = 0.0
    
    var tracking: Bool = false
    var origin: CGPoint = .zero

    var backgroundImageView: UIImageView!
    var buttonImageView: UIImageView!

    @IBOutlet weak var delegate: AnalogJoystickDelegate?
    
    var directionRaw: AnalogJoystickDirection = .both
    
    @IBInspectable
    @available(*, unavailable, message: "Interface Builder only")
    var direction: String = "both" {
        willSet {
            if let directionRaw = AnalogJoystickDirection(rawValue: newValue.lowercased()) {
                self.directionRaw = directionRaw
            }
        }
    }

    @IBInspectable
    var backgroundImage: UIImage? {
        didSet {
            self.backgroundImageView.image = backgroundImage
        }
    }
    
    @IBInspectable
    var fitSize: Bool = false {
        didSet {
            if fitSize {
                backgroundSize = bounds.width
            }
        }
    }
    
    @IBInspectable
    var backgroundSize: CGFloat = 100.0 {
        didSet {
            positionBackground()
        }
    }
    
    @IBInspectable
    var buttonImage: UIImage? {
        didSet {
            self.buttonImageView.image = buttonImage
        }
    }
    
    @IBInspectable
    var buttonSize: CGFloat = 50.0 {
        didSet {
            positionCenterButton()
        }
    }

    @IBInspectable
    var scalePosition: CGPoint = CGPoint(x: 1.0, y: 1.0)
    
    @IBInspectable
    var buttonOffset: CGPoint = CGPoint(x: 0.5, y: 0.5) {
        didSet {
            positionCenterButton()
        }
    }
    
    @IBInspectable
    var maxDistance: CGFloat = 50.0
    
    func positionBackground() {
        self.backgroundImageView.frame = CGRect(x: (bounds.width - backgroundSize) / 2,
                                                y: (bounds.height - backgroundSize) / 2,
                                                width: backgroundSize,
                                                height: backgroundSize)
    }
    
    func positionCenterButton() {
        self.buttonImageView.frame = CGRect(x: (bounds.width - buttonSize) / 2 + buttonOffset.x,
                                            y: (bounds.height - buttonSize) / 2 + buttonOffset.y,
                                            width: buttonSize,
                                            height: buttonSize)
    }
    
    func positionButton(_ position: CGPoint) {
        self.buttonImageView.frame = CGRect(x: (bounds.width - buttonSize) / 2 + buttonOffset.x + position.x,
                                            y: (bounds.height - buttonSize) / 2 + buttonOffset.y + position.y,
                                            width: buttonSize,
                                            height: buttonSize)
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    func setup() {
        backgroundColor = .clear
        
        backgroundImageView = UIImageView()
        backgroundImageView.contentMode = .scaleToFill
        addSubview(backgroundImageView)
        
        buttonImageView = UIImageView()
        buttonImageView.isUserInteractionEnabled = true
        buttonImageView.contentMode = .scaleToFill
        addSubview(buttonImageView)
        
        let dragGesture = UILongPressGestureRecognizer(target: self, action: #selector(self.handleButtonDrag(dragGesture:)))
        dragGesture.minimumPressDuration = 0
        
        buttonImageView.addGestureRecognizer(dragGesture)
    }
    
    @objc func handleButtonDrag(dragGesture: UILongPressGestureRecognizer) {
        if dragGesture.state == .began {
            tracking = true
            origin = dragGesture.location(in: self)
            delegate?.analogJoystickDidChange(self, position: .zero, angle: 0, mode: .began)
        } else if dragGesture.state == .changed {
            guard tracking else {
                return
            }
            let location = dragGesture.location(in: self)
            var position = CGPoint(x: location.x - origin.x, y: location.y - origin.y)
            switch directionRaw {
            case .both:
                let distance = sqrt(pow(position.x, 2) + pow(position.y, 2))
                position = distance <= maxDistance ?
                    CGPoint(x: position.x, y: position.y) :
                    CGPoint(x: position.x / distance * maxDistance, y: position.y / distance * maxDistance)
            case .horizontal:
                let distance = abs(position.x)
                position = distance <= maxDistance ?
                    CGPoint(x: position.x, y: 0) :
                    CGPoint(x: position.x / distance * maxDistance, y: 0)
            case .vertical:
                let distance = abs(position.y)
                position = distance <= maxDistance ?
                    CGPoint(x: 0, y: position.y) :
                    CGPoint(x: 0, y: position.y / distance * maxDistance)
            }
            positionButton(position)
            normPosition = CGPoint(x: position.x / maxDistance * scalePosition.x, y: position.y / maxDistance * scalePosition.y)
            angle = -atan2(position.x, position.y)
            delegate?.analogJoystickDidChange(self, position: normPosition, angle: angle, mode: .move)
        } else if dragGesture.state == .ended {
            resetStick()
        } else {
            resetStick()
        }
    }
    
    private func resetStick() {
        tracking = false
        origin = .zero
        UIView.animate(withDuration: 0.1, delay: 0, options: .curveEaseOut, animations: {
            self.positionCenterButton()
        }, completion: nil)
        delegate?.analogJoystickDidChange(self, position: .zero, angle: 0, mode: .end)
    }
    
    public override func layoutSubviews() {
        if fitSize {
            backgroundSize = bounds.width
        }
        positionBackground()
        positionCenterButton()
    }
}
