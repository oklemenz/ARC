//
//  CarSimulationAdvanced.swift
//  ARC
//
//  Created by Klemenz, Oliver on 14.12.17.
//  Copyright © 2017 Klemenz, Oliver. All rights reserved.
//

import Foundation
import UIKit
import SceneKit

let gravity: CGFloat = -9.81

public class Car : CarSimulation {
    
    let isPlayerControlled: Bool = true
    // Range(0..1)
    let cgHeight: CGFloat = 0.55
    // Range(0..2)
    let inertiaScale: CGFloat = 1
    let brakePower: CGFloat = 12000
    let eBrakePower: CGFloat = 10000 // 4800 // 5000
    // Range(0..1)
    let weightTransfer: CGFloat = 0.24 // 0.35
    // Range(0..1)
    let maxSteerAngle: CGFloat = 0.797 // 0.75
    // Range(0..20)
    let cornerStiffnessFront: CGFloat = 5.0
    // Range(0..20)
    let cornerStiffnessRear: CGFloat = 5.2
    // Range(0..20)
    let airResistance: CGFloat = 2.5
    // Range(0..20)
    let rollingResistance: CGFloat = 8.0
    // Range(0..1)
    let eBrakeGripRatioFront: CGFloat = 0.9
    // Range(0..5)
    let totalTireGripFront: CGFloat = 2.5
    // Range(0..1)
    let eBrakeGripRatioRear: CGFloat = 0.4
    // Range(0..5)
    let totalTireGripRear: CGFloat = 2.5
    // Range(0..5)
    let steerSpeed: CGFloat = 2.5
    // Range(0..5)
    let steerAdjustSpeed: CGFloat = 1
    // Range(0..1000)
    let speedSteerCorrection: CGFloat = 295 // 300
    // Range(0..20)
    let speedTurningStability: CGFloat = 11.8 // 10
    // Range(0..10)
    let axleDistanceCorrection: CGFloat = 1.7 // 2
    
    let trailAccelerationThreshold: CGFloat = 25
    let eBrakeSpeedThreshold: CGFloat = 40
    
    let axleFrontPos = CGPoint(x: 0, y: 0.86)
    let tireFrontLeftPos = CGPoint(x: -0.64, y: 0.861)
    let tireFrontRightPos = CGPoint(x: 0.64, y: 0.861)
    let axleRearPos = CGPoint(x: 0, y: -0.865)
    let tireRearLeftPos = CGPoint(x: -0.64, y: -0.865)
    let tireRearRightPos = CGPoint(x: 0.64, y: -0.865)
    
    let speedFactor: CGFloat = 0.065
    let rotationFactor: CGFloat = 0.05
    
    let mass: CGFloat = 1500 // Mass
    let linearDrag: CGFloat = 0.1 // Slow down velocity
    let angularDrag: CGFloat = 0.5 // Slow down angularVelocity
    let gravity: CGFloat = -9.81
    
    // Physics vars
    var headingAngle: CGFloat = 0
    var absoluteVelocity: CGFloat = 0
    var angularVelocity: CGFloat = 0
    var steerDirection: CGFloat = 0
    var steerAngle: CGFloat = 0
    var position: CGPoint = CGPoint(x: 0, y: 0)
    var originPosition: CGPoint = CGPoint(x: 0, y: 0)
    var rotation: CGFloat = 0
    var direction: CGFloat = 0
    var wheelRotation: CGFloat = 0
    var distance: CGFloat = 0
    var velocity: CGPoint = CGPoint(x: 0, y: 0)
    var acceleration: CGPoint = CGPoint(x: 0, y: 0)
    var localVelocity: CGPoint = CGPoint(x: 0, y: 0)
    var localAcceleration: CGPoint = CGPoint(x: 0, y: 0)
    var centerOfGravity: CGPoint = CGPoint(x: 0, y: -0.231)
    
    var inertia: CGFloat = 1
    var wheelBase: CGFloat = 1
    var trackWidth: CGFloat = 1
    
    var steer: CGFloat = 0
    var throttle: CGFloat = 0
    var brake: CGFloat = 0
    var eBrake: CGFloat = 0
    var eBrakeTriggerSpeed: CGFloat = 0
    
    var activeBrake: CGFloat = 0
    var activeThrottle: CGFloat = 0
    
    var frontWheelDrive: Bool = false
    var rearWheelDrive: Bool = true
    
    var axleFront: Axle!
    var axleRear: Axle!
    var engine: Engine!
    
    var car: CarVirtualObject!
    
    var objectContact: Bool = false
    var objectContactObstacle: ObstacleVirtualObject?
    var objectContactReverseDirection: CGFloat = 0
    
    var lastCurrentTime: TimeInterval?
    
    init(car: CarVirtualObject) {
        super.init()
        
        self.car = car
        
        position = CGPoint(x: CGFloat(car.position.z), y: CGFloat(car.position.x))
        originPosition = CGPoint(x: CGFloat(car.position.z), y: CGFloat(car.position.x))

        axleFront = Axle(car: self, tires: (left: car.wheelFrontLeft, right: car.wheelFrontRight))
        axleRear = Axle(car: self, tires: (left: car.wheelRearLeft, right: car.wheelRearRight))
        
        axleFront.position = axleFrontPos
        axleFront.tireLeft.position = tireFrontLeftPos
        axleFront.tireRight.position = tireFrontRightPos
        axleRear.position = axleRearPos
        axleRear.tireLeft.position = tireRearLeftPos
        axleRear.tireRight.position = tireRearRightPos
        
        engine = Engine(car: self)
        
        axleFront.distanceToCG = abs(centerOfGravity.y - axleFront.position.y)
        axleRear.distanceToCG = abs(centerOfGravity.y - axleRear.position.y)
        axleFront.distanceToCG *= axleDistanceCorrection
        axleRear.distanceToCG *= axleDistanceCorrection
        
        wheelBase = axleFront.distanceToCG + axleRear.distanceToCG
        inertia = mass * inertiaScale
        
        headingAngle = rotation
        
        axleFront.setup(wheelBase: wheelBase)
        axleRear.setup(wheelBase: wheelBase)
        
        trackWidth = abs(axleRear.tireLeft.position.x - axleRear.tireRight.position.x)
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
        velocity = CGPoint(x: -velocity.x / 5, y: -velocity.y / 5)
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
        return velocity.mag * 18 / 5
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
    
    override func update(steer: CGFloat, throttle: CGFloat, eBrake: CGFloat = 0, dt: CGFloat) {
        // Update from physics to retain collision responses
        // velocity = CGPoint(x: CGFloat(car.physicsBody!.velocity.z) / speedFactor, y: CGFloat(car.physicsBody!.velocity.x) / speedFactor)
        position = CGPoint(x: CGFloat(car.position.z), y: CGFloat(car.position.x))
        rotation = CGFloat(car.eulerAngles.y)
        headingAngle = rotation
        
        let sinVal = sin(headingAngle)
        let cosVal = cos(headingAngle)
        
        // Get local velocity
        localVelocity.x = cosVal * velocity.x + sinVal * velocity.y
        localVelocity.y = cosVal * velocity.y - sinVal * velocity.x
        
        // Direction
        direction = localVelocity.x == 0 ? 0 : localVelocity.x.sign
        
        // Prevent overlap => block
        var blocked: CGFloat = 0.0
        if objectContact && objectContactReverseDirection != 0 {
            if direction != objectContactReverseDirection {
                velocity = CGPoint(x: 0, y: 0)
                localVelocity = CGPoint(x: 0, y: 0)
            }
            if throttle.sign == objectContactReverseDirection {
                endContact()
            } else {
                blocked = 1.0
            }
        }
        
        // Weight transfer
        let transferX = weightTransfer * localAcceleration.x * cgHeight / wheelBase
        let transferY = weightTransfer * localAcceleration.y * cgHeight / trackWidth * 20 // exagerate the weight transfer on the y-axis
        
        // Weight on each axle
        let weightFront = mass * (axleFront.weightRatio * -gravity - transferX)
        let weightRear = mass * (axleRear.weightRatio * -gravity + transferX)
        
        // Weight on each tire
        axleFront.tireLeft.activeWeight = weightFront - transferY
        axleFront.tireRight.activeWeight = weightFront + transferY
        axleRear.tireLeft.activeWeight = weightRear - transferY
        axleRear.tireRight.activeWeight = weightRear + transferY
        
        // Velocity of each tire
        axleFront.tireLeft.angularVelocity = axleFront.distanceToCG * angularVelocity
        axleFront.tireRight.angularVelocity = axleFront.distanceToCG * angularVelocity
        axleRear.tireLeft.angularVelocity = -axleRear.distanceToCG * angularVelocity
        axleRear.tireRight.angularVelocity = -axleRear.distanceToCG * angularVelocity
        
        // Slip angle
        axleFront.slipAngle = atan2(localVelocity.y + axleFront.angularVelocity(), abs(localVelocity.x)) - localVelocity.x.sign * steerAngle
        axleRear.slipAngle = atan2(localVelocity.y + axleRear.angularVelocity(), abs(localVelocity.x))
        
        // Brake and Throttle power
        activeBrake = min(brake * brakePower + eBrake * eBrakePower, brakePower)
        activeThrottle = ((1 - blocked) * throttle * engine.torque()) * (engine.gearRatio() * engine.effectiveGearRatio())
        
        // Torque of each tire (front wheel drive)
        if frontWheelDrive {
            axleFront.tireLeft.torque = activeThrottle / axleFront.tireLeft.radius
            axleFront.tireRight.torque = activeThrottle / axleFront.tireRight.radius
        }
        
        // Torque of each tire (rear wheel drive)
        if rearWheelDrive {
            axleRear.tireLeft.torque = activeThrottle / axleRear.tireLeft.radius
            axleRear.tireRight.torque = activeThrottle / axleRear.tireRight.radius
        }
        
        // Grip and Friction of each tire
        axleFront.tireLeft.grip = totalTireGripFront * (1.0 - eBrake * (1.0 - eBrakeGripRatioFront))
        axleFront.tireRight.grip = totalTireGripFront * (1.0 - eBrake * (1.0 - eBrakeGripRatioFront))
        axleRear.tireLeft.grip = totalTireGripRear * (1.0 - eBrake * (1.0 - eBrakeGripRatioRear))
        axleRear.tireRight.grip = totalTireGripRear * (1.0 - eBrake * (1.0 - eBrakeGripRatioRear))
        
        axleFront.tireLeft.frictionForce = clamp(v: -cornerStiffnessFront * axleFront.slipAngle, vMin: -axleFront.tireLeft.grip, vMax: axleFront.tireLeft.grip) * axleFront.tireLeft.activeWeight
        axleFront.tireRight.frictionForce = clamp(v: -cornerStiffnessFront * axleFront.slipAngle, vMin: -axleFront.tireRight.grip, vMax: axleFront.tireRight.grip) * axleFront.tireRight.activeWeight
        axleRear.tireLeft.frictionForce = clamp(v: -cornerStiffnessRear * axleRear.slipAngle, vMin: -axleRear.tireLeft.grip, vMax: axleRear.tireLeft.grip) * axleRear.tireLeft.activeWeight
        axleRear.tireRight.frictionForce = clamp(v: -cornerStiffnessRear * axleRear.slipAngle, vMin: -axleRear.tireRight.grip, vMax: axleRear.tireRight.grip) * axleRear.tireRight.activeWeight
        
        // Forces
        var torque: CGFloat = 0
        if frontWheelDrive && rearWheelDrive {
            torque = (axleFront.torque() + axleRear.torque()) / 2
        } else if frontWheelDrive {
            torque = axleFront.torque()
        } else if rearWheelDrive {
            torque = axleRear.torque()
        }
        
        let tractionForceX = torque - activeBrake * localVelocity.x.sign
        let tractionForceY: CGFloat = 0
        
        let dragForceX = -rollingResistance * localVelocity.x - airResistance * localVelocity.x * abs(localVelocity.x)
        let dragForceY = -rollingResistance * localVelocity.y - airResistance * localVelocity.y * abs(localVelocity.y)
        
        let totalForceX = dragForceX + tractionForceX
        var totalForceY = dragForceY + tractionForceY + cos(steerAngle) * axleFront.frictionForce() + axleRear.frictionForce()
        
        // Adjust Y force so it levels out the car heading at high speeds
        if absoluteVelocity > 10 {
            totalForceY *= (absoluteVelocity + 1) / (21 - speedTurningStability)
        }
        
        // If we are not pressing gas, add artificial drag - helps with simulation stability
        if throttle == 0 {
            velocity = lerp(start: velocity, end: CGPoint(x: 0, y: 0), t: 0.005)
        }
        
        // Acceleration
        localAcceleration.x = totalForceX / mass
        localAcceleration.y = totalForceY / mass
        
        acceleration.x = cosVal * localAcceleration.x - sinVal * localAcceleration.y
        acceleration.y = sinVal * localAcceleration.x + cosVal * localAcceleration.y
        
        // Velocity and speed
        velocity.x += acceleration.x * dt
        velocity.y += acceleration.y * dt
        
        absoluteVelocity = velocity.mag
        
        // Angular torque of car
        var angularTorque = (axleFront.frictionForce() * axleFront.distanceToCG) - (axleRear.frictionForce() * axleRear.distanceToCG)
        // Car will drift away at low speeds
        if absoluteVelocity < 0.5 && activeThrottle == 0 {
            localAcceleration = CGPoint(x: 0, y: 0)
            absoluteVelocity = 0
            velocity = CGPoint(x: 0, y: 0)
            angularTorque = 0
            angularVelocity = 0
            acceleration = CGPoint(x: 0, y: 0)
            //angularVelocity = 0
        }
        let angularAcceleration = angularTorque / inertia
        
        // Update
        angularVelocity += angularAcceleration * dt
        
        // Simulation likes to calculate high angular velocity at very low speeds - adjust for this
        if absoluteVelocity < 1 && abs(steerAngle) < 0.05 {
            angularVelocity = 0
        } else if speedKilometersPerHour() < 0.75 {
            angularVelocity = 0
        }
        
        let rotationalSpeed = localVelocity.x.sign * velocity.mag / axleFront.tireLeft.radius * rotationFactor
        
        // Rotational Velocity of each tire
        axleFront.tireLeft.rotationalSpeed = rotationalSpeed
        axleFront.tireRight.rotationalSpeed = rotationalSpeed
        axleRear.tireLeft.rotationalSpeed = rotationalSpeed
        axleRear.tireRight.rotationalSpeed = rotationalSpeed
        
        // Simulate Wheel Rotation
        wheelRotation += rotationalSpeed
        
        headingAngle += angularVelocity * dt
        rotation = headingAngle
        
        // Update position by velocity
        position = position + velocity * dt * speedFactor
        distance = (position - originPosition).mag
        
        // Physics
        car.eulerAngles = SCNVector3(0, rotation, 0)
        // car.physicsBody?.velocity = SCNVector3(x: Float(velocity.y * speedFactor), y: 0, z: Float(velocity.x * speedFactor))
        car.position = SCNVector3(x: Float(position.y), y: car.position.y, z: Float(position.x))
        car.wheelFrontLeft.eulerAngles = SCNVector3(-wheelRotation, axleFront.tireLeft.rotation, 0)
        car.wheelFrontRight.eulerAngles = SCNVector3(-wheelRotation, axleFront.tireLeft.rotation, 0)
        car.wheelRearLeft.eulerAngles = SCNVector3(-wheelRotation, 0, 0)
        car.wheelRearRight.eulerAngles = SCNVector3(-wheelRotation, 0, 0)
        
        updateControl(steer: steer, throttle: throttle, eBrake: eBrake, dt: dt)
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
            
            // Apply filters to our steer direction
            steerDirection = smoothSteering(steerInput: steer, dt: dt)
            steerDirection = speedAdjustedSteering(steerInput: steerDirection)
            
            // Calculate the current angle the tires are pointing
            steerAngle = steerDirection * maxSteerAngle
            
            // Set front axle tires rotation
            axleFront.tireLeft.rotation = steerAngle
            axleFront.tireRight.rotation = steerAngle
        }
        
        // Calculate weight center of four tires
        // This is just to draw that red dot over the car to indicate what tires have the most weight
        var pos = CGPoint(x: 0, y: 0)
        if localAcceleration.mag > 1 {
            
            let wfl = max(0, (axleFront.tireLeft.activeWeight - axleFront.tireLeft.restingWeight))
            let wfr = max(0, (axleFront.tireRight.activeWeight - axleFront.tireRight.restingWeight))
            let wrl = max(0, (axleRear.tireLeft.activeWeight - axleRear.tireLeft.restingWeight))
            let wrr = max(0, (axleRear.tireRight.activeWeight - axleRear.tireRight.restingWeight))
            
            pos = axleFront.tireLeft.position * wfl + axleFront.tireRight.position * wfr +
                    axleRear.tireLeft.position * wrl + axleRear.tireRight.position * wrr
            
            let weightTotal = wfl + wfr + wrl + wrr
            
            if weightTotal > 0 {
                pos = pos / weightTotal
                pos = pos.norm
                pos.x = clamp(v: pos.x, vMin: -0.6, vMax: 0.6)
            } else {
                pos = CGPoint(x: 0, y: 0)
            }
        }
        
        // Update the "Center Of Gravity" dot to indicate the weight shift
        centerOfGravity = lerp(start: centerOfGravity, end: pos, t: 0.1)
        
        // Trail
        if (abs(localAcceleration.y) > trailAccelerationThreshold ||
           (eBrake > 0 && eBrakeTriggerSpeed > eBrakeSpeedThreshold)) && absoluteVelocity > 0 {
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
        
        // Automatic transmission
        engine.updateAutomaticTransmission()
    }
    
    func smoothSteering(steerInput: CGFloat, dt: CGFloat) -> CGFloat {
        var steer: CGFloat = 0
        
        if abs(steerInput) > 0.001 {
            steer = clamp(v: steerDirection - steerInput * dt * steerSpeed, vMin: -1.0, vMax: 1.0)
        } else {
            if steerDirection > 0 {
                steer = max(steerDirection - dt * steerAdjustSpeed, 0.0)
            } else if steerDirection < 0 {
                steer = min(steerDirection + dt * steerAdjustSpeed, 0.0)
            }
        }
        
        return steer
    }
    
    func speedAdjustedSteering(steerInput: CGFloat) -> CGFloat {
        let activeVelocity = min(absoluteVelocity, 250.0)
        let steer = steerInput * (1.0 - (activeVelocity / speedSteerCorrection))
        return steer
    }
    
    var previousCarModeSpeed: CGFloat = 0
    override func updateCarMode(speed: CGFloat, steer: CGFloat, throttle: CGFloat, eBrake: CGFloat = 0, dt: CGFloat) {
        if throttle == 0 {
            if speed == 0 {
                car.setCarMode(.idle)
            } else {
                car.setCarMode(.roll)
            }
            previousCarModeSpeed = 0
        } else {
            if throttle > 0 && speed - previousCarModeSpeed > 0 {
                car.setCarMode(.accelerate)
            } else if throttle < 0 {
                if speed > 0 && previousCarModeSpeed > 0 && speed - previousCarModeSpeed < 0 {
                    car.setCarMode(.decelerate)
                } else {
                    car.setCarMode(.drive)
                }
            } else {
                car.setCarMode(.drive)
            }
            previousCarModeSpeed = speed
        }
    }
}

class Axle {
    
    var position: CGPoint = CGPoint(x: 0, y: 0)
    var distanceToCG : CGFloat = 0
    var weightRatio: CGFloat = 0
    var slipAngle: CGFloat = 0
    
    var car: Car!
    var tireLeft: Tire!
    var tireRight: Tire!

    init(car: Car, tires: (left: SCNNode, right: SCNNode)) {
        self.car = car
        self.tireLeft = Tire(car: car, object: tires.left)
        self.tireRight = Tire(car: car, object: tires.right)
    }
    
    func setup(wheelBase: CGFloat) {
        // Weight distribution on each axle and tire
        weightRatio = distanceToCG / wheelBase
        
        // Calculate resting weight of each Tire
        let weight = car.mass * (weightRatio * -gravity)
        tireLeft.restingWeight = weight
        tireRight.restingWeight = weight
    }
    
    func frictionForce() -> CGFloat {
        return (tireLeft.frictionForce + tireRight.frictionForce) / 2
    }
    
    func angularVelocity() -> CGFloat {
        return tireLeft.angularVelocity + tireRight.angularVelocity
    }
    
    func torque() -> CGFloat {
        return (tireLeft.torque + tireRight.torque) / 2
    }
}

class Tire {

    let radius: CGFloat = 0.5
    
    var position: CGPoint = CGPoint(x: 0, y: 0)
    var restingWeight: CGFloat = 0
    var activeWeight: CGFloat = 0
    var grip: CGFloat = 0
    var frictionForce: CGFloat = 0
    var angularVelocity: CGFloat = 0
    var rotationalSpeed: CGFloat = 0
    var torque: CGFloat = 0
    var rotation: CGFloat = 0
    
    var trailDuration: CGFloat = 5
    var trailActive: Bool = false
    
    var car: Car!
    var object: SCNNode!
    
    init(car: Car, object: SCNNode) {
        self.car = car
        self.object = object
    }
    
    func setTrailActive(_ active: Bool) {
        if active && !trailActive {
            // Start Particle System
        } else if !active && trailActive {
            // Stop Particle System
        }
        trailActive = active
    }
}

class Engine {

    let torqueCurve: [CGFloat] = [50, 150, 200, 350, 400, 300, 150, 100] // [100, 280, 325, 420, 460, 340, 300, 100]
    let gearRatios: [CGFloat] = [14, 10, 8.5, 7, 6, 5, 4.2] // [5.8, 4.5, 3.74, 2.8, 1.6, 0.79, 4.2]
    
    var currentGear = 0

    var car: Car!
    
    init(car: Car) {
        self.car = car
    }
    
    func gearRatio() -> CGFloat {
        return gearRatios[currentGear]
    }
    
    func effectiveGearRatio() -> CGFloat {
        return gearRatios[gearRatios.count - 1]
    }
    
    func shiftUp() {
        currentGear += 1
    }
    
    func shiftDown() {
        currentGear -= 1
    }
    
    func torque() -> CGFloat {
        return torqueRPM(rpm())
    }
    
    func rpm() -> CGFloat {
        return car.velocity.mag / (π * 2 / 60) * (gearRatio() * effectiveGearRatio())
    }
    
    func torqueRPM(_ rpm: CGFloat) -> CGFloat {
        if rpm < 1000 {
            return lerp(a: torqueCurve[0], b: torqueCurve[1], n: rpm / 1000)
        } else if rpm < 2000 {
            return lerp(a: torqueCurve[1], b: torqueCurve[2], n: (rpm - 1000) / 1000)
        } else if rpm < 3000 {
            return lerp(a: torqueCurve[2], b: torqueCurve[3], n: (rpm - 2000) / 1000)
        } else if rpm < 4000 {
            return lerp(a: torqueCurve[3], b: torqueCurve[4], n: (rpm - 3000) / 1000)
        } else if rpm < 5000 {
            return lerp(a: torqueCurve[4], b: torqueCurve[5], n: (rpm - 4000) / 1000)
        } else if rpm < 6000 {
            return lerp(a: torqueCurve[5], b: torqueCurve[6], n: (rpm - 5000) / 1000)
        } else if rpm < 7000 {
            return lerp(a: torqueCurve[6], b: torqueCurve[7], n: (rpm - 6000) / 1000)
        } else {
            return torqueCurve[6]
        }
    }
    
    func updateAutomaticTransmission() {
        let rpmVal = rpm()
        if rpmVal > 6200 {
            if currentGear < 5 {
                currentGear += 1
            }
        } else if rpmVal < 2000 {
            if currentGear > 0 {
                currentGear -= 1
            }
        }
    }
}

