/*
See LICENSE folder for this sample’s licensing information.

Abstract:
ARSCNViewDelegate interactions for `ViewController`.
*/

import ARKit

extension ViewController: ARSCNViewDelegate, ARSessionDelegate {
    
    // MARK: - ARSCNViewDelegate
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        DispatchQueue.main.async {
            self.virtualObjectInteraction.updateObjectToCurrentTrackingPosition()
            if !self.focusSquare.isHidden {
                self.updateFocusSquare()
            }
        }
        
        // If light estimation is enabled, update the intensity of the model's lights and the environment map
        let baseIntensity: CGFloat = 40
        let lightingEnvironment = sceneView.scene.lightingEnvironment
        if let lightEstimate = session.currentFrame?.lightEstimate {
            lightingEnvironment.intensity = lightEstimate.ambientIntensity / baseIntensity
        } else {
            lightingEnvironment.intensity = baseIntensity
        }
       
        let dt: CGFloat = CGFloat(lastCurrentTime != nil ? time - lastCurrentTime! : 0)
        if let carSimulation = carSimulation,
            let car = car {
            let speed = carSimulation.speedKilometersPerHour()
            let eBrake = CGFloat(brake && brakeThreshold <= 0 && speed > brakeThresholdSpeed ? 1 : 0)
            carSimulation.update(steer: steer, throttle: throttle, eBrake: eBrake, dt: dt)
            car.update(carSimulation: carSimulation, dt: dt)
            if brake {
                brakeThreshold -= dt
            }
        }
        lastCurrentTime = time
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        DispatchQueue.main.async {
            self.statusViewController.cancelScheduledMessage(for: .planeEstimation)
            if !self.carDrivingActive {
                self.statusViewController.showMessage("Surface detected")
                if self.virtualObjectLoader.loadedObjects.isEmpty {
                    self.statusViewController.scheduleMessage("Tap object buttons to place an object on focus square", inSeconds: 7.5, messageType: .contentPlacement)
                }
            } else {
                self.statusViewController.cancelScheduledMessage(for: .contentPlacement)
            }
        }
        updateQueue.async {
            self.syncObjectsOnPlane(planeAnchor: planeAnchor, node: node)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        updateQueue.async {
            if self.car == nil || self.car!.carMode == .idle {
                self.syncObjectsOnPlane(planeAnchor: planeAnchor, node: node)
            }
        }
    }
    
    func syncObjectsOnPlane(planeAnchor: ARPlaneAnchor, node: SCNNode) {
        for object in self.virtualObjectLoader.loadedObjects {
            _ = object.adjustOntoPlaneAnchor(planeAnchor, using: node)
        }
    }
    
    func session(_ session: ARSession, cameraDidChangeTrackingState camera: ARCamera) {
        statusViewController.showTrackingQualityInfo(for: camera.trackingState, autoHide: true)
        
        switch camera.trackingState {
        case .notAvailable, .limited:
            statusViewController.escalateFeedback(for: camera.trackingState, inSeconds: 3.0)
        case .normal:
            statusViewController.cancelScheduledMessage(for: .trackingStateEscalation)
        }
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        guard error is ARError else { return }
        
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        
        // Use `flatMap(_:)` to remove optional error messages.
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        
        DispatchQueue.main.async {
            self.displayErrorMessage(title: "The AR session failed.", message: errorMessage)
        }
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        blurView.isHidden = false
        statusViewController.showMessage("Session interrupted.\nThe session will be reset after the interruption has ended.", autoHide: false)
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        blurView.isHidden = true
        statusViewController.showMessage("Resetting session")
        
        restartExperience()
    }
}
