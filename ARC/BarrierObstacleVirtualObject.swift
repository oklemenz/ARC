//
//  BarrierObstacleVirtualObject.swift
//  ARC
//
//  Created by Klemenz, Oliver on 10.01.18.
//  Copyright © 2018 Klemenz, Oliver. All rights reserved.
//

import Foundation
import SceneKit
import ARKit

class BarrierObstacleVirtualObject: ObstacleVirtualObject {
    
    override public init?(url: URL) {
        super.init(url: url)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func setup() {
        super.setup()
        
        let concrete = childNode(withName: "concrete", recursively: true)!
        let boundingBoxMin = convertPosition(concrete.boundingBox.min, from: concrete)
        let boundingBoxMax = convertPosition(concrete.boundingBox.max, from: concrete)
        boundingBox = (min: boundingBoxMin, max: boundingBoxMax)
        
        let box = SCNBox(width: 0.25, height: 0.5, length: 0.95, chamferRadius: 0)
        let boxShape = SCNPhysicsShape(geometry: box, options: [SCNPhysicsShape.Option.scale: SCNVector3(0.20, 0.20, 0.20)])
        let bodyShape = SCNPhysicsShape(shapes: [boxShape], transforms: [NSValue(scnMatrix4:SCNMatrix4MakeTranslation(0.0, 0.25 * 0.20, 0.0))])
        physicsBody = SCNPhysicsBody(type: .static, shape: bodyShape)
        physicsBody?.isAffectedByGravity = false
        physicsBody?.categoryBitMask = PhysicsCategory.obstacle.rawValue
        physicsBody?.collisionBitMask = PhysicsCategory.car.rawValue
        physicsBody?.contactTestBitMask = PhysicsCategory.car.rawValue
    }
    
    override func shiftedClone(direction: Float, camera: ARCamera?) -> BarrierObstacleVirtualObject? {
        var localPosition = convertPosition(position, from: parent!)
        localPosition = SCNVector3(x: localPosition.x,
                                   y: localPosition.y,
                                   z: localPosition.z + direction * (boundingBox.max.z - boundingBox.min.z + 0.005))
        let clone = self.clone()
        clone.setup()
        clone.position = parent!.convertPosition(localPosition, from: self)
        return clone
    }
    
    override func initRotate(camera: ARCamera) {
        eulerAngles.y = camera.eulerAngles.y + .pi / 2
    }
}
