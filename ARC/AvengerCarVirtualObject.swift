//
//  AvengerCarVirtualObject.swift
//  ARC
//
//  Created by Klemenz, Oliver on 26.01.18.
//  Copyright © 2018 Klemenz, Oliver. All rights reserved.
//

import Foundation
import SceneKit
import ARKit

class AvengerCarVirtualObject: CarVirtualObject {
    
    override public init?(type: String, url: URL) {
        super.init(type: type, url: url)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func setup() {
        super.setup()
        
        let box = SCNBox(width: 0.5, height: 0.3, length: 1.15, chamferRadius: 0)
        let boxShape = SCNPhysicsShape(geometry: box, options: [SCNPhysicsShape.Option.scale: SCNVector3(0.20, 0.20, 0.20)])
        let bodyShape = SCNPhysicsShape(shapes: [boxShape], transforms: [NSValue(scnMatrix4:SCNMatrix4MakeTranslation(0.0, 0.15 * 0.2, 0.0))])
        physicsBody = SCNPhysicsBody(type: .dynamic, shape: bodyShape)
        physicsBody?.mass = 1000
        physicsBody?.isAffectedByGravity = false
        physicsBody?.velocityFactor = SCNVector3(1, 0, 1)
        physicsBody?.angularVelocityFactor = SCNVector3(0, 1, 0)
        physicsBody?.categoryBitMask = PhysicsCategory.car.rawValue
    }
}
