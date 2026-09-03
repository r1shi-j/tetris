//
//  GamepadManager.swift
//  tetris
//
//  Created by Rishi Jansari on 03/09/2026.
//


import GameController

@Observable
class GamepadManager {
    var onMoveLeft: (() -> Void)?
    var onMoveRight: (() -> Void)?
    var onSoftDrop: (() -> Void)?
    var onHardDrop: (() -> Void)?
    var onRotate: (() -> Void)?
    var onRestart: (() -> Void)?
    
    private var hasTiltedStick = false
    
    init() {
        NotificationCenter.default.addObserver(
            forName: .GCControllerDidConnect,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let controller = notification.object as? GCController {
                self?.configure(controller: controller)
            }
        }
        
        if let controller = GCController.controllers().first {
            configure(controller: controller)
        }
    }
    
    private func configure(controller: GCController) {
        guard let gamepad = controller.extendedGamepad else { return }
        // 1. D-Pad
        gamepad.dpad.left.pressedChangedHandler = { [weak self] _, _, pressed in
            if pressed { self?.onMoveLeft?() }
        }
        gamepad.dpad.right.pressedChangedHandler = { [weak self] _, _, pressed in
            if pressed { self?.onMoveRight?() }
        }
//        gamepad.dpad.up.pressedChangedHandler = { [weak self] _, _, pressed in
//            if pressed { self?.onRotate?() }
//        }
        gamepad.dpad.down.pressedChangedHandler = { [weak self] _, _, pressed in
            if pressed { self?.onSoftDrop?() }
        }
        
        // 2. Left Thumbstick (analog stick)
        gamepad.leftThumbstick.valueChangedHandler = { [weak self] _, x, y in
            guard let self = self else { return }
            let deadzone: Float = 0.5
            
            if !self.hasTiltedStick {
                if x < -deadzone {
                    self.onMoveLeft?()
                    self.hasTiltedStick = true
                } else if x > deadzone {
                    self.onMoveRight?()
                    self.hasTiltedStick = true
                } else if y < -deadzone {
                    self.onSoftDrop?()
                    self.hasTiltedStick = true
                } else if y > deadzone {
//                    self.onRotate?()
//                    self.hasTiltedStick = true
                }
            } else if abs(x) < 0.2 && abs(y) < 0.2 {
                // Reset flag when stick returns to center
                self.hasTiltedStick = false
            }
        }
        
        // 3. Left Shoulders (L or ZL) -> Rotate
        gamepad.leftShoulder.pressedChangedHandler = { [weak self] _, _, pressed in
            if pressed { self?.onRotate?() }
        }
        gamepad.leftTrigger.pressedChangedHandler = { [weak self] _, _, pressed in
            if pressed { self?.onRotate?() }
        }
        
        // 4. Right Shoulders (R or ZR) -> Hard Drop
        gamepad.rightShoulder.pressedChangedHandler = { [weak self] _, _, pressed in
            if pressed { self?.onHardDrop?() }
        }
        gamepad.rightTrigger.pressedChangedHandler = { [weak self] _, _, pressed in
            if pressed { self?.onHardDrop?() }
        }
        
        // 5. Face Buttons
        // buttonY = Top button -> Rotate
        gamepad.buttonY.pressedChangedHandler = { [weak self] _, _, pressed in
            if pressed { self?.onRotate?() }
        }
        // buttonA = Bottom button -> Hard Drop
        gamepad.buttonA.pressedChangedHandler = { [weak self] _, _, pressed in
            if pressed { self?.onHardDrop?() }
        }
        
        // 6. Plus / Minus Buttons -> Restart
        // buttonMenu = Plus button (+), buttonOptions = Minus button (-)
        gamepad.buttonMenu.pressedChangedHandler = { [weak self] _, _, pressed in
            if pressed { self?.onRestart?() }
        }
        gamepad.buttonOptions?.pressedChangedHandler = { [weak self] _, _, pressed in
            if pressed { self?.onRestart?() }
        }
    }
}
