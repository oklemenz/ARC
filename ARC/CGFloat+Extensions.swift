//
//  CGFloat+Extensions.swift
//  ACR
//
//  Created by Klemenz, Oliver on 08.12.17.
//  Copyright © 2017 Oliver Klemenz. All rights reserved.
//

import CoreGraphics

/** The value of π as a CGFloat */
let π = CGFloat.pi

public extension CGFloat {
    
    /**
     * Converts an angle in degrees to radians.
     */
    public var degToRad: CGFloat {
        return π * self / 180.0
    }
    
    /**
     * Converts an angle in radians to degrees.
     */
    public var radToDeg: CGFloat {
        return self * 180.0 / π
    }
    
    /**
     * Ensures that the float value stays between the given values, inclusive.
     */
    public func clamped(_ v1: CGFloat, _ v2: CGFloat) -> CGFloat {
        let min = v1 < v2 ? v1 : v2
        let max = v1 > v2 ? v1 : v2
        return self < min ? min : (self > max ? max : self)
    }
    
    /**
     * Ensures that the float value stays between the given values, inclusive.
     */
    public mutating func clamp(_ v1: CGFloat, _ v2: CGFloat) -> CGFloat {
        self = clamped(v1, v2)
        return self
    }
    
    /**
     * Returns 1.0 if a floating point value is positive, -1.0 if it is negative.
     */
    public var sign: CGFloat {
        return (self >= 0.0) ? 1.0 : -1.0
    }
    
    /**
     * Returns a random floating point number between 0.0 and 1.0, inclusive.
     */
    public static func random() -> CGFloat {
        return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
    }
    
    /**
     * Returns a random floating point number in the range min...max, inclusive.
     */
    public static func random(min: CGFloat, max: CGFloat) -> CGFloat {
        assert(min < max)
        return CGFloat.random() * (max - min) + min
    }
    
    /**
     * Randomly returns either 1.0 or -1.0.
     */
    public static func randomSign() -> CGFloat {
        return (arc4random_uniform(2) == 0) ? 1.0 : -1.0
    }
}

/**
 * Returns the shortest angle between two angles. The result is always between
 * -π and π.
 */
public func shortestAngleBetween(_ angle1: CGFloat, angle2: CGFloat) -> CGFloat {
    let twoπ = π * 2.0
    var angle = (angle2 - angle1).truncatingRemainder(dividingBy: twoπ)
    if angle >= π {
        angle = angle - twoπ
    }
    if angle <= -π {
        angle = angle + twoπ
    }
    return angle
}

/**
 * Linear interpolation
 */
public func lerp(a: CGFloat, b: CGFloat, n: CGFloat) -> CGFloat {
    return (1 - n) * a + n * b
}

/**
 * Ensures that the float value stays between the given values, inclusive.
 */
public func clamp(v: CGFloat, vMin: CGFloat, vMax: CGFloat) -> CGFloat {
    return min(max(vMin, v), vMax)
}
