//
//  CarSimulation.swift
//  ARC
//
//  Created by Klemenz, Oliver on 20.12.17.
//  Copyright © 2017 Klemenz, Oliver. All rights reserved.
//

import Foundation
import UIKit

public class CarSimulation {
    
    func setup(fourWheelDrive: Bool) {
    }

    func speedKilometersPerHour() -> CGFloat {
        return 0
    }

    func notifyContact(contactDirection: Int, obstacle: ObstacleVirtualObject) {
    }
    
    func update(steer: CGFloat, throttle: CGFloat, eBrake: CGFloat = 0, dt: CGFloat) {
    }
    
    func updateCarMode(speed: CGFloat, steer: CGFloat, throttle: CGFloat, eBrake: CGFloat = 0, dt: CGFloat) {
    }
}
