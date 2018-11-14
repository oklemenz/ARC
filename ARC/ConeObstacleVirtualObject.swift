//
//  ConeObstacleVirtualObject.swift
//  ARC
//
//  Created by Klemenz, Oliver on 24.01.18.
//  Copyright © 2018 Klemenz, Oliver. All rights reserved.
//

import Foundation

import Foundation
import SceneKit
import ARKit

class ConeObstacleVirtualObject: ObstacleVirtualObject {
    
    override public init?(url: URL) {
        super.init(url: url)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func setup() {
        super.setup()
        
        let cone = SCNCone(topRadius: 0.0, bottomRadius: 0.075, height: 0.75)
        let coneShape = SCNPhysicsShape(geometry: cone, options: [SCNPhysicsShape.Option.scale: SCNVector3(0.10, 0.10, 0.10)])
        let bodyShape = SCNPhysicsShape(shapes: [coneShape], transforms: [NSValue(scnMatrix4:SCNMatrix4MakeTranslation(0.0, 0.5 * 0.10, 0.0))])
        physicsBody = SCNPhysicsBody(type: .static, shape: bodyShape)
        physicsBody?.isAffectedByGravity = false
        physicsBody?.categoryBitMask = PhysicsCategory.obstacle.rawValue
        physicsBody?.collisionBitMask = PhysicsCategory.car.rawValue
        physicsBody?.contactTestBitMask = PhysicsCategory.car.rawValue
    }
    
    override func shiftedClone(direction: Float, camera: ARCamera?) -> ObstacleVirtualObject? {
        guard camera != nil else {
            return nil
        }
        let yRotation = eulerAngles.y
        eulerAngles.y = 0
        let xDir = sin(camera!.eulerAngles.y)
        let zDir = cos(camera!.eulerAngles.y)
        var localPosition = convertPosition(position, from: parent!)
        localPosition = SCNVector3(x: localPosition.x - xDir * 7 *
            (boundingBox.max.x - boundingBox.min.x + 0.005),
                                   y: localPosition.y,
                                   z: localPosition.z - zDir * 7 *
            (boundingBox.max.z - boundingBox.min.z + 0.005))
        let clone = self.clone()
        clone.setup()
        clone.position = parent!.convertPosition(localPosition, from: self)
        clone.eulerAngles.y = yRotation
        eulerAngles.y = yRotation
        return clone
    }
}
