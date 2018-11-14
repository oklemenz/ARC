//
//  CarVirtualObject.swift
//  ARC
//
//  Created by Klemenz, Oliver on 21.12.17.
//  Copyright © 2017 Klemenz, Oliver. All rights reserved.
//

import Foundation
import SceneKit
import ARKit

struct CarMode: OptionSet {
    let rawValue: Int
    
    static let idle = CarMode(rawValue: 1)
    static let roll = CarMode(rawValue: 2)
    static let drive = CarMode(rawValue: 4)
    static let accelerate = CarMode(rawValue: 8)
    static let decelerate = CarMode(rawValue: 16)
    static let squeak = CarMode(rawValue: 32)
    static let crash = CarMode(rawValue: 64)
    
    static let move: CarMode = [.roll, .drive, .accelerate, .decelerate]
}

@objc
protocol CarVirtualObjectDelegate {
    func isSoundMuted() -> Bool
}

class CarVirtualObject: VirtualObject {
    
    let defaultTrailBirthRate: CGFloat = 25
    let defaultSkidmarkBirthRate: CGFloat = 1
    
    var wheelFrontLeft: SCNNode!
    var wheelFrontRight: SCNNode!
    var wheelRearLeft: SCNNode!
    var wheelRearRight: SCNNode!
    
    var wheelFrontLeftTrailSpot: SCNNode!
    var wheelFrontRightTrailSpot: SCNNode!
    var wheelRearLeftTrailSpot: SCNNode!
    var wheelRearRightTrailSpot: SCNNode!

    var wheelFrontLeftSkidmarkSpot: SCNNode!
    var wheelFrontRightSkidmarkSpot: SCNNode!
    var wheelRearLeftSkidmarkSpot: SCNNode!
    var wheelRearRightSkidmarkSpot: SCNNode!
    
    var wheelFrontLeftTrail: SCNParticleSystem!
    var wheelFrontRightTrail: SCNParticleSystem!
    var wheelRearLeftTrail: SCNParticleSystem!
    var wheelRearRightTrail: SCNParticleSystem!
    
    var wheelFrontLeftSkidmark: SCNParticleSystem!
    var wheelFrontRightSkidmark: SCNParticleSystem!
    var wheelRearLeftSkidmark: SCNParticleSystem!
    var wheelRearRightSkidmark: SCNParticleSystem!
    
    var sparks: SCNParticleSystem!
    
    var idleAudioSource: SCNAudioSource!
    var idleAudioPlayer: SCNAudioPlayer!
    var idleAudioEmitterNode: SCNNode?
    
    var driveAudioSource: SCNAudioSource!
    var driveAudioPlayer: SCNAudioPlayer!
    var driveAudioEmitterNode: SCNNode?
    
    var accelerateAudioSource: SCNAudioSource!
    var accelerateAudioPlayer: SCNAudioPlayer!
    var accelerateAudioEmitterNode: SCNNode?
    
    var decelerateAudioSource: SCNAudioSource!
    var decelerateAudioPlayer: SCNAudioPlayer!
    var decelerateAudioEmitterNode: SCNNode?
    
    var squeakAudioSource: SCNAudioSource!
    var squeakAudioPlayer: SCNAudioPlayer!
    var squeakAudioEmitterNode: SCNNode?
    
    var crashAudioSource: SCNAudioSource!
    var crashAudioPlayer: SCNAudioPlayer!
    var crashAudioEmitterNode: SCNNode?
    
    var type: String = ""
    var carMode: CarMode = []
        
    weak var delegate: CarVirtualObjectDelegate?
    
    public init?(type: String, url: URL) {
        super.init(url: url)
        self.type = type
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func setup() {
        super.setup()
        
        initWheels()
        initSounds()
    }
    
    override func initRotate(camera: ARCamera) {
        eulerAngles.y = camera.eulerAngles.y + .pi
    }
    
    func resetCar() {
        wheelFrontLeftTrailActive = false
        wheelFrontRightTrailActive = false
        wheelRearLeftTrailActive = false
        wheelRearRightTrailActive = false
        setCarMode([])
    }
    
    func initWheels() {
        wheelFrontLeft = childNode(withName: "wheel_front_left", recursively: true)
        wheelFrontLeftTrail = SCNParticleSystem(named: "Trail.scnp", inDirectory: nil)!
        wheelFrontLeftTrail.birthRate = 0
        wheelFrontLeftTrailSpot = childNode(withName: "wheel_front_left_trail", recursively: true)
        wheelFrontLeftTrailSpot.addParticleSystem(wheelFrontLeftTrail)
        wheelFrontLeftSkidmark = SCNParticleSystem(named: "Skidmark.scnp", inDirectory: nil)!
        wheelFrontLeftSkidmark.birthRate = 0
        wheelFrontLeftSkidmarkSpot = childNode(withName: "wheel_front_left_skidmark", recursively: true)
        wheelFrontLeftSkidmarkSpot.addParticleSystem(wheelFrontLeftSkidmark)
        
        wheelFrontRight = childNode(withName: "wheel_front_right", recursively: true)
        wheelFrontRightTrail = SCNParticleSystem(named: "Trail.scnp", inDirectory: nil)!
        wheelFrontRightTrail.birthRate = 0
        wheelFrontRightTrailSpot = childNode(withName: "wheel_front_right_trail", recursively: true)
        wheelFrontRightTrailSpot.addParticleSystem(wheelFrontRightTrail)
        wheelFrontRightSkidmark = SCNParticleSystem(named: "Skidmark.scnp", inDirectory: nil)!
        wheelFrontRightSkidmark.birthRate = 0
        wheelFrontRightSkidmarkSpot = childNode(withName: "wheel_front_right_skidmark", recursively: true)
        wheelFrontRightSkidmarkSpot.addParticleSystem(wheelFrontRightSkidmark)
        
        wheelRearLeft = childNode(withName: "wheel_back_left", recursively: true)
        wheelRearLeftTrail = SCNParticleSystem(named: "Trail.scnp", inDirectory: nil)!
        wheelRearLeftTrail.birthRate = 0
        wheelRearLeftTrailSpot = childNode(withName: "wheel_back_left_trail", recursively: true)
        wheelRearLeftTrailSpot.addParticleSystem(wheelRearLeftTrail)
        wheelRearLeftSkidmark = SCNParticleSystem(named: "Skidmark.scnp", inDirectory: nil)!
        wheelRearLeftSkidmark.birthRate = 0
        wheelRearLeftSkidmarkSpot = childNode(withName: "wheel_back_left_skidmark", recursively: true)
        wheelRearLeftSkidmarkSpot.addParticleSystem(wheelRearLeftSkidmark)
        
        wheelRearRight = childNode(withName: "wheel_back_right", recursively: true)
        wheelRearRightTrail = SCNParticleSystem(named: "Trail.scnp", inDirectory: nil)!
        wheelRearRightTrail.birthRate = 0
        wheelRearRightTrailSpot = childNode(withName: "wheel_back_right_trail", recursively: true)
        wheelRearRightTrailSpot.addParticleSystem(wheelRearRightTrail)
        wheelRearRightSkidmark = SCNParticleSystem(named: "Skidmark.scnp", inDirectory: nil)!
        wheelRearRightSkidmark.birthRate = 0
        wheelRearRightSkidmarkSpot = childNode(withName: "wheel_back_right_skidmark", recursively: true)
        wheelRearRightSkidmarkSpot.addParticleSystem(wheelRearRightSkidmark)
    }
    
    override func adjustOntoPlaneAnchor(_ anchor: ARPlaneAnchor, using node: SCNNode) -> Float {
        // Do not adjust car during driving
        if carMode == .idle {
            return super.adjustOntoPlaneAnchor(anchor, using: node)
        }
        return 0
    }
    
    var wheelFrontLeftTrailActive: Bool {
        set {
            wheelFrontLeftTrail.birthRate = newValue ? defaultTrailBirthRate : 0
            wheelFrontLeftSkidmark.birthRate = newValue ? defaultSkidmarkBirthRate : 0
        }
        get {
            return wheelFrontLeftTrail.birthRate > 0
        }
    }
    
    var wheelFrontRightTrailActive: Bool {
        set {
            wheelFrontRightTrail.birthRate = newValue ? defaultTrailBirthRate : 0
            wheelFrontRightSkidmark.birthRate = newValue ? defaultSkidmarkBirthRate : 0
        }
        get {
            return wheelFrontRightTrail.birthRate > 0
        }
    }
    
    var wheelRearLeftTrailActive: Bool {
        set {
            wheelRearLeftTrail.birthRate = newValue ? defaultTrailBirthRate : 0
            wheelRearLeftSkidmark.birthRate = newValue ? defaultSkidmarkBirthRate : 0
        }
        get {
            return wheelRearLeftTrail.birthRate > 0
        }
    }
    
    var wheelRearRightTrailActive: Bool {
        set {
            wheelRearRightTrail.birthRate = newValue ? defaultTrailBirthRate : 0
            wheelRearRightSkidmark.birthRate = newValue ? defaultSkidmarkBirthRate : 0
        }
        get {
            return wheelRearRightTrail.birthRate > 0
        }
    }
    
    func initSounds() {
        idleAudioSource = SCNAudioSource(fileNamed: "\(type)_idle.wav")!
        idleAudioSource.loops = true
        idleAudioSource.load()
        idleAudioPlayer = SCNAudioPlayer(source: idleAudioSource)
        addAudioPlayer(idleAudioPlayer)

        driveAudioSource = SCNAudioSource(fileNamed: "\(type)_drive.wav")!
        driveAudioSource.loops = true
        driveAudioSource.load()
        driveAudioPlayer = SCNAudioPlayer(source: driveAudioSource)
        addAudioPlayer(driveAudioPlayer)
        
        accelerateAudioSource = SCNAudioSource(fileNamed: "\(type)_accelerate.wav")!
        accelerateAudioSource.loops = true
        accelerateAudioSource.load()
        accelerateAudioPlayer = SCNAudioPlayer(source: accelerateAudioSource)
        addAudioPlayer(accelerateAudioPlayer)
        
        decelerateAudioSource = SCNAudioSource(fileNamed: "\(type)_decelerate.wav")!
        decelerateAudioSource.loops = true
        decelerateAudioSource.load()
        decelerateAudioPlayer = SCNAudioPlayer(source: decelerateAudioSource)
        addAudioPlayer(decelerateAudioPlayer)
        
        squeakAudioSource = SCNAudioSource(fileNamed: "\(type)_squeak.wav")!
        squeakAudioSource.volume = 0.5
        squeakAudioSource.loops = true
        squeakAudioSource.load()
        squeakAudioPlayer = SCNAudioPlayer(source: squeakAudioSource)
        addAudioPlayer(squeakAudioPlayer)
        
        crashAudioSource = SCNAudioSource(fileNamed: "\(type)_crash.wav")!
        crashAudioSource.loops = false
        crashAudioSource.load()
        crashAudioPlayer = SCNAudioPlayer(source: crashAudioSource)
        addAudioPlayer(crashAudioPlayer)
    }
    
    func update(carSimulation: CarSimulation, dt: CGFloat) {
        /* Variate sound according to car simulation => Use SoundManager
        if carMode.contains(.drive) {
            if let driveAudioNode = driveAudioPlayer!.audioNode as? AVAudioPlayerNode {
                driveAudioNode.volume = Float(clamp(v: carSimulation.speedKilometersPerHour() / 100, vMin: 0.0, vMax: 1.0))
                driveAudioNode.rate = 0.5 + Float(clamp(v: carSimulation.speedKilometersPerHour() / 100, vMin: 0.0, vMax: 1.5))
            }
        }*/
        wheelFrontLeftSkidmark.particleAngle = CGFloat(eulerAngles.y).radToDeg
        wheelFrontRightSkidmark.particleAngle = CGFloat(eulerAngles.y).radToDeg
        wheelRearLeftSkidmark.particleAngle = CGFloat(eulerAngles.y).radToDeg
        wheelRearRightSkidmark.particleAngle = CGFloat(eulerAngles.y).radToDeg
    }
    
    func notifyContact(carSimulation: CarSimulation, obstacle: ObstacleVirtualObject, contactSpot: SCNNode?, contactDirection: Int) {
        if contactDirection == 1 && carSimulation.speedKilometersPerHour() > 5 {
            setCarMode(.crash)
            let sparks = SCNParticleSystem(named: "Sparks.scnp", inDirectory: nil)!
            sparks.particleSize = 0.00001
            contactSpot?.addParticleSystem(sparks)
        }
    }
    
    func setCarMode(_ carMode: CarMode) {
        if carMode.isEmpty {
            stopIdleSound()
            stopDriveSound()
            stopAccelerateSound()
            stopDecelerateSound()
            stopSqueakSound()
        }
        if carMode == .idle && self.carMode != .idle {
            self.carMode = .idle
            startIdleSound()
            stopDriveSound()
            stopAccelerateSound()
            stopDecelerateSound()
            stopSqueakSound()
        }
        if CarMode.move.contains(carMode) {
            if carMode.contains(.roll) && !self.carMode.contains(.roll) {
                self.carMode.insert(.roll)
                startRollSound()
                if self.carMode.contains(.drive) {
                    self.carMode.remove(.drive)
                    stopDriveSound()
                }
                if self.carMode.contains(.accelerate) {
                    self.carMode.remove(.accelerate)
                    stopAccelerateSound()
                }
                if self.carMode.contains(.decelerate) {
                    self.carMode.remove(.decelerate)
                    stopDecelerateSound()
                }
            } else {
                if self.carMode.contains(.idle) {
                    self.carMode.remove(.idle)
                    stopIdleSound()
                }
            }
            if carMode.contains(.drive) && !self.carMode.contains(.drive) {
                self.carMode.insert(.drive)
                startDriveSound()
                if self.carMode.contains(.roll) {
                    self.carMode.remove(.roll)
                    stopRollSound()
                }
                if self.carMode.contains(.accelerate) {
                    self.carMode.remove(.accelerate)
                    stopAccelerateSound()
                }
                if self.carMode.contains(.decelerate) {
                    self.carMode.remove(.decelerate)
                    stopDecelerateSound()
                }
            } else if carMode.contains(.accelerate) && !self.carMode.contains(.accelerate) {
                self.carMode.insert(.accelerate)
                startAccelerateSound()
                if self.carMode.contains(.roll) {
                    self.carMode.remove(.roll)
                    stopRollSound()
                }
                if self.carMode.contains(.drive) {
                    self.carMode.remove(.drive)
                    stopDriveSound()
                }
                if self.carMode.contains(.decelerate) {
                    self.carMode.remove(.decelerate)
                    stopDecelerateSound()
                }
            } else if carMode.contains(.decelerate) && !self.carMode.contains(.decelerate) {
                self.carMode.insert(.decelerate)
                startDecelerateSound()
                if self.carMode.contains(.roll) {
                    self.carMode.remove(.roll)
                    stopRollSound()
                }
                if self.carMode.contains(.drive) {
                    self.carMode.remove(.drive)
                    stopDriveSound()
                }
                if self.carMode.contains(.accelerate) {
                    self.carMode.remove(.accelerate)
                    stopAccelerateSound()
                }
            }
        }
        if carMode.contains(.squeak) && !self.carMode.contains(.squeak) {
            self.carMode.insert(.squeak)
            startSqueakSound()
        }
        if carMode.contains(.crash) && !self.carMode.contains(.crash) {
            self.carMode.insert(.crash)
            startCrashSound()
        }
    }
    
    func unsetCarMode(_ carMode: CarMode) {
        if carMode.contains(.squeak) && self.carMode.contains(.squeak) {
            self.carMode.remove(.squeak)
            self.stopSqueakSound()
        }
        if carMode.contains(.crash) && self.carMode.contains(.crash) {
            self.carMode.remove(.crash)
            self.stopSqueakSound()
        }
    }
    
    func startIdleSound() {
        if delegate?.isSoundMuted() == false {
            if idleAudioEmitterNode == nil {
                idleAudioEmitterNode = SCNNode()
                idleAudioEmitterNode!.position = position
                addChildNode(idleAudioEmitterNode!)
                idleAudioEmitterNode!.runAction(SCNAction.playAudio(idleAudioSource, waitForCompletion: false))
            }
        }
    }
    
    func stopIdleSound() {
        if let idleAudioEmitterNode = idleAudioEmitterNode {
            idleAudioEmitterNode.removeFromParentNode()            
        }
        idleAudioEmitterNode = nil
    }
    
    func startRollSound() {
        startIdleSound()
    }
    
    func stopRollSound() {
        stopIdleSound()
    }
    
    func startDriveSound() {
        if delegate?.isSoundMuted() == false {
            if driveAudioEmitterNode == nil {
                driveAudioEmitterNode = SCNNode()
                driveAudioEmitterNode!.position = position
                addChildNode(driveAudioEmitterNode!)
                driveAudioEmitterNode!.runAction(SCNAction.playAudio(driveAudioSource, waitForCompletion: false))
            }
        }
    }
    
    func stopDriveSound() {
        if let driveAudioEmitterNode = driveAudioEmitterNode {
            driveAudioEmitterNode.removeFromParentNode()
        }
        driveAudioEmitterNode = nil
    }
    
    func startAccelerateSound() {
        if delegate?.isSoundMuted() == false {
            if accelerateAudioEmitterNode == nil {
                accelerateAudioEmitterNode = SCNNode()
                accelerateAudioEmitterNode!.position = position
                addChildNode(accelerateAudioEmitterNode!)
                accelerateAudioEmitterNode!.runAction(SCNAction.playAudio(accelerateAudioSource, waitForCompletion: false))
            }
        }
    }
    
    func stopAccelerateSound() {
        if let accelerateAudioEmitterNode = accelerateAudioEmitterNode {
            accelerateAudioEmitterNode.removeFromParentNode()
        }
        accelerateAudioEmitterNode = nil
    }
    
    func startDecelerateSound() {
        if delegate?.isSoundMuted() == false {
            if decelerateAudioEmitterNode == nil {
                decelerateAudioEmitterNode = SCNNode()
                decelerateAudioEmitterNode!.position = position
                addChildNode(decelerateAudioEmitterNode!)
                decelerateAudioEmitterNode!.runAction(SCNAction.playAudio(decelerateAudioSource, waitForCompletion: false))
            }
        }
    }
    
    func stopDecelerateSound() {
        if let decelerateAudioEmitterNode = decelerateAudioEmitterNode {
            decelerateAudioEmitterNode.removeFromParentNode()
        }
        decelerateAudioEmitterNode = nil
    }
    
    func startSqueakSound() {
        if delegate?.isSoundMuted() == false {
            if squeakAudioEmitterNode == nil {
                squeakAudioEmitterNode = SCNNode()
                squeakAudioEmitterNode!.position = position
                addChildNode(squeakAudioEmitterNode!)
                squeakAudioEmitterNode!.runAction(SCNAction.playAudio(squeakAudioSource, waitForCompletion: false))
            }
        }
    }
    
    func stopSqueakSound() {
        if let squeakAudioEmitterNode = squeakAudioEmitterNode {
            squeakAudioEmitterNode.removeFromParentNode()
        }
        squeakAudioEmitterNode = nil
    }
    
    func startCrashSound() {
        if delegate?.isSoundMuted() == false {
            if crashAudioEmitterNode == nil {
                crashAudioEmitterNode = SCNNode()
                crashAudioEmitterNode!.position = position
                addChildNode(crashAudioEmitterNode!)
                crashAudioEmitterNode!.runAction(SCNAction.sequence([
                    SCNAction.playAudio(crashAudioSource, waitForCompletion: true),
                    SCNAction.run({ (node) in
                        self.stopCrashSound()
                    })
                ]))
            }
        }
    }
    
    func stopCrashSound() {
        if let crashAudioEmitterNode = crashAudioEmitterNode {
            crashAudioEmitterNode.removeFromParentNode()
        }
        crashAudioEmitterNode = nil
        self.carMode.remove(.crash)
    }
}
