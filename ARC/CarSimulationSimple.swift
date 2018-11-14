//
//  CarSimulationSimple.swift
//  ARC
//
//  Created by Klemenz, Oliver on 14.12.17.
//  Copyright © 2017 Klemenz, Oliver. All rights reserved.
//

import Foundation
import UIKit
import SceneKit

public class SimpleCar : CarSimulation {
 
    var car: CarVirtualObject!
    
    var objectContact: Bool = false
    var objectContactObstacle: ObstacleVirtualObject?
    var objectContactReverseDirection: CGFloat = 0
    
    let isPlayerControlled: Bool = true
    
    let velocitySpeed: CGFloat = 0.02
    let velocitySpeedBrake: CGFloat = 0.01
    let velocitySpeedDamping: CGFloat = 0.007
    let velocityMax: CGFloat = 0.8
    let steerAngleSpeed: CGFloat = 0.04
    let steerAngleSpeedDamping: CGFloat = 0.025
    let driftDampening: CGFloat = 0.2
    let steerAngleMax: CGFloat = 35 * π / 180
    let wheelBase: CGFloat = 100 // Distance front and rear axle
    let wheelRadius: CGFloat = 0.5
    let speedFactor: CGFloat = 50
    let rotationFactor: CGFloat = 1.25
    
    let trailAccelerationThreshold: CGFloat = 25
    let eBrakeSpeedThreshold: CGFloat = 40
    
    var frontWheelDrive = false
    var rearWheelDrive = true
    
    var position = CGPoint(x: 0, y: 0)
    var originPosition = CGPoint(x: 0, y: 0)

    var velocity: CGFloat = 0
    var steerAngle: CGFloat = 0
    var headingAngle: CGFloat = 0
    var rotationAngle: CGFloat = 0
    var localVelocity: CGPoint = CGPoint(x: 0, y: 0)
    var velocity2: CGPoint = CGPoint(x: 0, y: 0)
    
    var steer: CGFloat = 0
    var throttle: CGFloat = 0
    var eBrake: CGFloat = 0
    var eBrakeTriggerSpeed: CGFloat = 0
    var direction: CGFloat = 0
    var wheelRotation: CGFloat = 0
    var rotationalSpeed: CGFloat = 0
    var distance: CGFloat = 0
    
    init(car: CarVirtualObject) {
        super.init()
        
        self.car = car
        
        position = CGPoint(x: CGFloat(car.position.z), y: CGFloat(car.position.x))
        originPosition = CGPoint(x: CGFloat(car.position.z), y: CGFloat(car.position.x))
    }
    
    override func setup(fourWheelDrive: Bool) {
        if fourWheelDrive {
            frontWheelDrive = true
            rearWheelDrive = true
        } else {
            frontWheelDrive = false
            rearWheelDrive = true
        }
    }
    
    override func notifyContact(contactDirection: Int, obstacle: ObstacleVirtualObject) {
        if contactDirection == 1 && !objectContact && (objectContactObstacle == nil || obstacle != objectContactObstacle) {
            beginContact(obstacle: obstacle)
        }
        if contactDirection == -1 && obstacle == objectContactObstacle {
            endContact()
        }
    }
    
    func beginContact(obstacle: ObstacleVirtualObject) {
        velocity = -velocity / 5
        objectContactReverseDirection = -direction
        objectContactObstacle = obstacle
        objectContact = true
    }
    
    func endContact() {
        objectContactReverseDirection = 0
        objectContactObstacle = nil
        objectContact = false
    }
    
    override func speedKilometersPerHour() -> CGFloat {
        return velocity2.mag * 18 / 5 * CGFloat(speedFactor)
    }
    
    override func update(steer: CGFloat, throttle: CGFloat, eBrake: CGFloat = 0, dt: CGFloat) {
        rotationAngle = CGFloat(car.eulerAngles.y)
        position = CGPoint(x: CGFloat(car.position.z), y: CGFloat(car.position.x))
        
        let effectiveSteerAngle = steerAngle * 0.25
        headingAngle = rotationAngle
        let cosVal = cos(headingAngle)
        let sinVal = sin(headingAngle)
        var frontWheel = CGPoint(x: position.x + wheelBase / 2 * cosVal,
                                 y: position.y + wheelBase / 2 * sinVal)
        var backWheel = CGPoint(x: position.x - wheelBase / 2 * cosVal,
                                y: position.y - wheelBase / 2 * sinVal)
        frontWheel = CGPoint(x: frontWheel.x + velocity * dt * cos(headingAngle + effectiveSteerAngle),
                             y: frontWheel.y + velocity * dt * sin(headingAngle + effectiveSteerAngle))
        backWheel = CGPoint(x: backWheel.x + velocity * dt * cosVal,
                            y: backWheel.y + velocity * dt * sinVal)
        let newPosition = CGPoint(x: (frontWheel.x + backWheel.x) / 2, y: (frontWheel.y + backWheel.y) / 2)
        headingAngle = atan2(frontWheel.y - backWheel.y, frontWheel.x - backWheel.x)
        headingAngle = headingAngle + (effectiveSteerAngle * (velocity / velocityMax) * driftDampening) // Drift
        rotationAngle = headingAngle
        
        velocity2 = CGPoint(x: (newPosition.x - position.x) / dt, y: (newPosition.y - position.y) / dt)
        position = newPosition
        // velocity2 = CGPoint(x: velocity * cosVal, y: velocity * sinVal)
        localVelocity.x = cosVal * velocity2.x + sinVal * velocity2.y
        localVelocity.y = cosVal * velocity2.y - sinVal * velocity2.x
        direction = localVelocity.x == 0 ? 0 : localVelocity.x.sign
        
        // Prevent overlap => block
        var blocked: CGFloat = 0.0
        if objectContact && objectContactReverseDirection != 0 {
            if direction != objectContactReverseDirection {
                velocity = 0
                velocity2 = CGPoint(x: 0, y: 0)
                localVelocity = CGPoint(x: 0, y: 0)
            }
            if throttle.sign == objectContactReverseDirection {
                endContact()
            } else {
                blocked = 1.0
            }
        }
        
        rotationalSpeed = localVelocity.x.sign * velocity2.mag / wheelRadius / rotationFactor
        wheelRotation += rotationalSpeed
        distance = (position - originPosition).mag
        
        // Trail
        if (eBrake > 0 && eBrakeTriggerSpeed > eBrakeSpeedThreshold) && velocity != 0 {
            if frontWheelDrive && rearWheelDrive {
                car.wheelFrontLeftTrailActive = true
                car.wheelFrontRightTrailActive = true
                car.wheelRearLeftTrailActive = true
                car.wheelRearRightTrailActive = true
            } else if frontWheelDrive {
                car.wheelFrontLeftTrailActive = true
                car.wheelFrontRightTrailActive = true
            } else if rearWheelDrive {
                car.wheelRearLeftTrailActive = true
                car.wheelRearRightTrailActive = true
            }
            car.setCarMode(.squeak)
        } else {
            car.wheelFrontLeftTrailActive = false
            car.wheelFrontRightTrailActive = false
            car.wheelRearLeftTrailActive = false
            car.wheelRearRightTrailActive = false
            car.unsetCarMode(.squeak)
        }
        
        // Physics
        car.eulerAngles = SCNVector3(0, rotationAngle, 0)
        // car.physicsBody?.velocity = SCNVector3(x: Float(velocity2.y), y: 0, z: Float(velocity2.x))
        car.position = SCNVector3(x: Float(position.y), y: car.position.y, z: Float(position.x))
        car.wheelFrontLeft.eulerAngles = SCNVector3(-wheelRotation, steerAngle, 0)
        car.wheelFrontRight.eulerAngles = SCNVector3(-wheelRotation, steerAngle, 0)
        car.wheelRearLeft.eulerAngles = SCNVector3(-wheelRotation, 0, 0)
        car.wheelRearRight.eulerAngles = SCNVector3(-wheelRotation, 0, 0)
        
        updateControl(steer: steer, throttle: (1 - blocked) * throttle, eBrake: eBrake, dt: dt)
        updateCarMode(speed: localVelocity.x.sign * speedKilometersPerHour(), steer: steer, throttle: throttle, eBrake: eBrake, dt: dt)
    }
    
    func updateControl(steer: CGFloat, throttle: CGFloat, eBrake: CGFloat = 0, dt: CGFloat) {
        if isPlayerControlled {
            self.steer = steer
            self.throttle = throttle
            if self.eBrake == 0 && eBrake > 0 {
                self.eBrakeTriggerSpeed = speedKilometersPerHour()
            } else if eBrake == 0 {
                self.eBrakeTriggerSpeed = 0
            }
            self.eBrake = eBrake
            
            // Steering
            if steer > 0 {
                steerAngle = steerAngle - steerAngleSpeed * steer
                steerAngle = max(steerAngle, -steerAngleMax)
            } else if steer < 0 {
                steerAngle = steerAngle - steerAngleSpeed * steer
                steerAngle = min(steerAngle, steerAngleMax)
            }
            // Accelerating
            if throttle > 0 {
                velocity = velocity + velocitySpeed * throttle
                velocity = min(velocity, velocityMax)
            } else if throttle < 0 {
                velocity = velocity + velocitySpeed * throttle
                velocity = max(velocity, -velocityMax)
            }
            // Brake
            if eBrake > 0 {
                if velocity > 0 {
                    velocity = velocity - velocitySpeedBrake * eBrake
                    velocity = max(velocity, 0)
                } else {
                    velocity = velocity + velocitySpeedBrake * eBrake
                    velocity = min(velocity, 0)
                }
            }
            // Center
            if steer == 0 {
                if steerAngle > 0 {
                    steerAngle = steerAngle - steerAngleSpeedDamping
                    steerAngle = max(steerAngle, 0)
                } else {
                    steerAngle = steerAngle + steerAngleSpeedDamping
                    steerAngle = min(steerAngle, 0)
                }
            }
            // Friction
            if throttle == 0 {
                if velocity > 0 {
                    velocity = velocity - velocitySpeedDamping
                    velocity = max(velocity, 0)
                } else {
                    velocity = velocity + velocitySpeedDamping
                    velocity = min(velocity, 0)
                }
            }
        }
    }
    
    override func updateCarMode(speed: CGFloat, steer: CGFloat, throttle: CGFloat, eBrake: CGFloat = 0, dt: CGFloat) {
        if throttle == 0 {
            if speed == 0 {
                car.setCarMode(.idle)
            } else {
                car.setCarMode(.roll)
            }
        } else {
            car.setCarMode(.drive)
        }
    }
}
