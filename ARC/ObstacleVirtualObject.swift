//
//  ObstacleVirtualObject.swift
//  ARC
//
//  Created by Klemenz, Oliver on 07.01.18.
//  Copyright © 2018 Klemenz, Oliver. All rights reserved.
//

import Foundation
import SceneKit
import ARKit

class ObstacleVirtualObject: VirtualObject {
    
    override public init?(url: URL) {
        super.init(url: url)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func setup() {
        super.setup()
    }
}
