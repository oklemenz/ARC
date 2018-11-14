//
//  TireObstacleVirtualObject.swift
//  ARC
//
//  Created by Klemenz, Oliver on 24.01.18.
//  Copyright © 2018 Klemenz, Oliver. All rights reserved.
//

import Foundation

import Foundation
import SceneKit
import ARKit

class TireObstacleVirtualObject: ObstacleVirtualObject {
    
    override public init?(url: URL) {
        super.init(url: url)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func setup() {
        super.setup()
        
        let cylinder = SCNCylinder(radius: 0.32, height: 0.3)
        let cylinderShape = SCNPhysicsShape(geometry: cylinder, options: [SCNPhysicsShape.Option.scale: SCNVector3(0.20, 0.20, 0.20)])
        let bodyShape = SCNPhysicsShape(shapes: [cylinderShape], transforms: [NSValue(scnMatrix4:SCNMatrix4MakeTranslation(0.0, 0.15 * 0.20, 0.0))])
        physicsBody = SCNPhysicsBody(type: .static, shape: bodyShape)
        physicsBody?.isAffectedByGravity = false
        physicsBody?.categoryBitMask = PhysicsCategory.obstacle.rawValue
        physicsBody?.collisionBitMask = PhysicsCategory.car.rawValue
        physicsBody?.contactTestBitMask = PhysicsCategory.car.rawValue
    }
    
    override func shiftedClone(direction: Float, camera: ARCamera?) -> ObstacleVirtualObject? {
        let target = deepestTire()
        let clone = target.clone()
        clone.setup()
        clone.physicsBody = nil
        let randomX = Float(arc4random()) / Float(UINT32_MAX) - 0.5
        let randomZ = Float(arc4random()) / Float(UINT32_MAX) - 0.5
        clone.position = SCNVector3(x: randomX * 0.05 * 0.20,
                                    y: 0.17 * 0.20,
                                    z: randomZ * 0.05 * 0.20)
        let shadowPlane = clone.childNode(withName: "shadowPlane", recursively: true)
        shadowPlane?.removeFromParentNode()
        target.addChildNode(clone)
        return nil
    }
    
    func deepestTire() -> TireObstacleVirtualObject {
        for childNode in childNodes {
            if let tireChildNode = childNode as? TireObstacleVirtualObject {
                return tireChildNode.deepestTire()
            }
        }
        return self
    }
}
