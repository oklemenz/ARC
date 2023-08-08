/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A `SCNReferenceNode` subclass for virtual objects placed into the AR scene.
*/

import Foundation
import SceneKit
import ARKit

enum PhysicsCategory: Int {
    case none = 0
    case car = 1
    case obstacle = 2
}

class VirtualObject: SCNReferenceNode {
    
    /// The model name derived from the `referenceURL`.
    var modelName: String {
        return referenceURL.lastPathComponent.replacingOccurrences(of: ".scn", with: "")
    }
    
    /// Use average of recent virtual object distances to avoid rapid changes in object scale.
    private var recentVirtualObjectDistances = [Float]()

    override public init?(url: URL) {
        super.init(url: url)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func load() {
        if !isLoaded {
            super.load()
            setup()
        }
    }
    
    func setup() {
    }
    
    func initRotate(camera: ARCamera) {        
    }
    
    /// Resets the objects poisition smoothing.
    func reset() {
        recentVirtualObjectDistances.removeAll()
    }
    
    /**
     Set the object's position based on the provided position relative to the `cameraTransform`.
     If `smoothMovement` is true, the new position will be averaged with previous position to
     avoid large jumps.
     
     - Tag: VirtualObjectSetPosition
     */
    func setPosition(_ newPosition: SIMD3<Float>, relativeTo cameraTransform: matrix_float4x4, smoothMovement: Bool) {
        let cameraWorldPosition = cameraTransform.translation
        var positionOffsetFromCamera = newPosition - cameraWorldPosition
        
        // Limit the distance of the object from the camera to a maximum of 10 meters.
        if simd_length(positionOffsetFromCamera) > 10 {
            positionOffsetFromCamera = simd_normalize(positionOffsetFromCamera)
            positionOffsetFromCamera *= 10
        }
        
        /*
         Compute the average distance of the object from the camera over the last ten
         updates. Notice that the distance is applied to the vector from
         the camera to the content, so it affects only the percieved distance to the
         object. Averaging does _not_ make the content "lag".
         */
        if smoothMovement {
            let hitTestResultDistance = simd_length(positionOffsetFromCamera)
            
            // Add the latest position and keep up to 10 recent distances to smooth with.
            recentVirtualObjectDistances.append(hitTestResultDistance)
            recentVirtualObjectDistances = Array(recentVirtualObjectDistances.suffix(10))
            
            let averageDistance = recentVirtualObjectDistances.average!
            let averagedDistancePosition = simd_normalize(positionOffsetFromCamera) * averageDistance
            simdPosition = cameraWorldPosition + averagedDistancePosition
        } else {
            simdPosition = cameraWorldPosition + positionOffsetFromCamera
        }
    }
    
    /// - Tag: AdjustOntoPlaneAnchor
    func adjustOntoPlaneAnchor(_ anchor: ARPlaneAnchor, using node: SCNNode) -> Float {
        // Get the object's position in the plane's coordinate system.
        let planePosition = node.convertPosition(position, from: parent)
        
        // Check that the object is not already on the plane.
        guard planePosition.y != 0 else { return 0 }
        
        // Planes are infinite
        
        // Add 10% tolerance to the corners of the plane.
        /*let tolerance: Float = 0.1

        let minX: Float = anchor.center.x - anchor.extent.x / 2 - anchor.extent.x * tolerance
        let maxX: Float = anchor.center.x + anchor.extent.x / 2 + anchor.extent.x * tolerance
        let minZ: Float = anchor.center.z - anchor.extent.z / 2 - anchor.extent.z * tolerance
        let maxZ: Float = anchor.center.z + anchor.extent.z / 2 + anchor.extent.z * tolerance
        
        guard (minX...maxX).contains(planePosition.x) && (minZ...maxZ).contains(planePosition.z) else {
            return 0
        }*/
        
        // Move onto the plane if it is near it (within 10 centimeters).
        let verticalAllowance: Float = 0.10
        let epsilon: Float = 0.001 // Do not update if the difference is less than 1 mm.
        let distanceToPlane = abs(planePosition.y)
        if distanceToPlane > epsilon && distanceToPlane < verticalAllowance {
            SCNTransaction.begin()
            SCNTransaction.animationDuration = CFTimeInterval(distanceToPlane * 500) // Move 2 mm per second.
            SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            position.y = anchor.transform.columns.3.y
            SCNTransaction.commit()
            return position.y
        }
        return 0
    }
    
    func shiftedClone(direction: Float, camera: ARCamera?) -> VirtualObject? {
        return nil
    }
    
    var root: VirtualObject {
        var node = self
        while node.parent is VirtualObject {
            node = node.parent as! VirtualObject
        }
        return node
    }
}

extension VirtualObject {
    // MARK: Static Properties and Methods
    
    /// Loads all the model objects within `Models.scnassets`.
    static let availableObjects: [VirtualObject] = {
        let modelsURL = Bundle.main.url(forResource: "Models.scnassets", withExtension: nil)!

        let fileEnumerator = FileManager().enumerator(at: modelsURL, includingPropertiesForKeys: [])!

        return fileEnumerator.compactMap { element in
            let url = element as! URL

            guard url.pathExtension == "scn" else { return nil }

            return VirtualObject(url: url)
        }
    }()
    
    /// Returns a `VirtualObject` if one exists as an ancestor to the provided node.
    static func existingObjectContainingNode(_ node: SCNNode) -> VirtualObject? {
        if let virtualObjectRoot = node as? VirtualObject {
            return virtualObjectRoot
        }
        
        guard let parent = node.parent else { return nil }
        
        // Recurse up to check if the parent is a `VirtualObject`.
        return existingObjectContainingNode(parent)
    }
    
    static var _barrierObject: BarrierObstacleVirtualObject?
    static func barrierObject() -> BarrierObstacleVirtualObject {
        if _barrierObject == nil {
            _barrierObject = BarrierObstacleVirtualObject(url: Bundle.main.url(forResource: "Models.scnassets/barrier/barrier.scn", withExtension: nil)!)!
        }
        return _barrierObject!.clone()
    }
    
    static var _tireObject: TireObstacleVirtualObject?
    static func tireObject() -> TireObstacleVirtualObject {
        if _tireObject == nil {
           _tireObject = TireObstacleVirtualObject(url:Bundle.main.url(forResource: "Models.scnassets/tire/tire.scn", withExtension: nil)!)!
        }
        return _tireObject!.clone()
    }
    
    static var _coneObject: ConeObstacleVirtualObject?
    static func coneObject() -> ConeObstacleVirtualObject {
        if _coneObject == nil {
            _coneObject = ConeObstacleVirtualObject(url:Bundle.main.url(forResource: "Models.scnassets/cone/cone.scn", withExtension: nil)!)!
        }
        return _coneObject!.clone()
    }
    
    static var _defenderCar: DefenderCarVirtualObject?
    static func defenderCar() -> DefenderCarVirtualObject {
        if _defenderCar == nil {
            _defenderCar = DefenderCarVirtualObject(type: "defender", url: Bundle.main.url(forResource: "Models.scnassets/defender/defender.scn", withExtension: nil)!)!
        }
        return _defenderCar!
    }
    
    static var _avengerCar: AvengerCarVirtualObject?
    static func avengerCar() -> AvengerCarVirtualObject {
        if _avengerCar == nil {
            _avengerCar = AvengerCarVirtualObject(type: "avenger", url:Bundle.main.url(forResource: "Models.scnassets/avenger/avenger.scn", withExtension: nil)!)!
        }
        return _avengerCar!
    }
    
    static var _legoCar: LegoCarVirtualObject?
    static func legoCar() -> LegoCarVirtualObject {
        if _legoCar == nil {
            _legoCar = LegoCarVirtualObject(type: "lego", url:Bundle.main.url(forResource: "Models.scnassets/lego/lego.scn", withExtension: nil)!)!
        }
        return _legoCar!
    }
}

extension Collection where Iterator.Element == Float {
    /// Return the mean of a list of Floats. Used with `recentVirtualObjectDistances`.
    var average: Float? {
        guard !isEmpty else {
            return nil
        }

        let sum = reduce(Float(0)) { current, next -> Float in
            return current + next
        }

        return sum / Float(count)
    }
}
