/*
See LICENSE folder for this sample’s licensing information.

Abstract:
A type which loads and tracks virtual objects.
*/

import Foundation
import ARKit

/**
 Loads multiple `VirtualObject`s on a background queue to be able to display the
 objects quickly once they are needed.
*/
class VirtualObjectLoader {
	var loadedObjects = [VirtualObject]()
    var isLoading = false
	
	// MARK: - Loading object

    /**
     Loads a `VirtualObject` on a background queue. `loadedHandler` is invoked
     on a background queue once `object` has been loaded.
    */
    func loadVirtualObject(_ object: VirtualObject, loadedHandler: @escaping (VirtualObject) -> Void) {
        isLoading = true
		addVirtualObject(object)
		
		// Load the content asynchronously.
        DispatchQueue.global(qos: .userInitiated).async {
            object.reset()
            object.load()

            self.isLoading = false
            loadedHandler(object)
        }
	}
    
    // MARK: - Adding Objects
    func addVirtualObject(_ object: VirtualObject, contextObject: VirtualObject? = nil) {
        loadedObjects.append(object)
    }
    
    // MARK: - Removing Objects
    func removeAllVirtualObjects() {
        // Reverse the indicies so we don't trample over indicies as objects are removed.
        for index in loadedObjects.indices.reversed() {
            removeVirtualObject(at: index)
        }
    }
    
    func removeVirtualObject(_ object: VirtualObject) {        
        if let objectIndex = loadedObjects.firstIndex(of: object) {
            removeVirtualObject(at: objectIndex)
        }
    }
    
    private func removeVirtualObject(at index: Int) {
        guard loadedObjects.indices.contains(index) else { return }
        loadedObjects[index].removeFromParentNode()
        loadedObjects.remove(at: index)
    }
}
