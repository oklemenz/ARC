/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Main view controller for the AR experience.
*/

import ARKit
import SceneKit
import UIKit

class ViewController: UIViewController, AnalogJoystickDelegate, VirtualObjectInteractionDelegate, CarVirtualObjectDelegate, SCNPhysicsContactDelegate {
    
    var steer: CGFloat = 0
    var throttle: CGFloat = 0
    var brake: Bool = false
    var brakeThreshold: CGFloat = 0
    let brakeThresholdDefault: CGFloat = 0.5
    let brakeThresholdSpeed: CGFloat = 10
    
    var raceMode: Bool = true
    var soundMuted: Bool = false

    var car: CarVirtualObject?
    var carSimulation: CarSimulation?
    var fourWheelDrive: Bool = false
    var carDrivingActive: Bool = false
    
    var lastCurrentTime: TimeInterval?
    
    var fadeJoystickTimer: Timer?
    
    @IBOutlet weak var leftAnalogJoystickWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var leftAnalogJoystickLeftMarginConstraint: NSLayoutConstraint!
    @IBOutlet weak var leftAnalogJoystickBottomMarginConstraint: NSLayoutConstraint!

    @IBOutlet weak var rightAnalogJoystickWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightAnalogJoystickRightMarginConstraint: NSLayoutConstraint!
    @IBOutlet weak var rightAnalogJoystickBottomMarginConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var objectContainerLeftMarginConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var actionContainerRightMarginConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var carContainerBottomMarginContainer: NSLayoutConstraint!
    
    func analogJoystickDidChange(_ analogJoystick: AnalogJoystick, position: CGPoint, angle: CGFloat, mode: AnalogJoystickMode) {
        if analogJoystick == leftAnalogJoystick {
            throttle = position.y
            brake = mode == .end
            if mode == .end {
                brakeThreshold = brakeThresholdDefault
            }
        } else if analogJoystick == rightAnalogJoystick {
            steer = position.x
        }
        if leftAnalogJoystick.tracking && rightAnalogJoystick.tracking {
            if fadeJoystickTimer == nil {
                fadeJoystickTimer = setTimeout(1.0, completed: {
                    UIView.animate(withDuration: 0.5, animations: {
                        self.leftAnalogJoystick.alpha = 0.25
                        self.rightAnalogJoystick.alpha = 0.25
                    })
                })
            }
        } else {
            fadeJoystickTimer?.invalidate()
            fadeJoystickTimer = nil
            UIView.animate(withDuration: 0.5, animations: {
                self.leftAnalogJoystick.alpha = 1.0
                self.rightAnalogJoystick.alpha = 1.0
            })
        }
    }
    
    func setTimeout(_ delay: TimeInterval, completed: @escaping () -> Void) -> Timer {
        return Timer.scheduledTimer(timeInterval: delay, target: BlockOperation(block: completed),
                                    selector: #selector(Operation.main), userInfo: nil, repeats: false)
    }
    
    func isSoundMuted() -> Bool {
        return soundMuted
    }
    
    // MARK: IBOutlets
    
    @IBOutlet var sceneView: VirtualObjectARView!
    
    @IBOutlet weak var leftAnalogJoystick: AnalogJoystick!
    
    @IBOutlet weak var rightAnalogJoystick: AnalogJoystick!
    
    @IBOutlet weak var blurView: UIVisualEffectView!
    
    @IBOutlet weak var spinner: UIActivityIndicatorView!

    @IBOutlet weak var objectButtonContainer: UIStackView!
    
    @IBOutlet weak var addBarrierButton: BlurButton!
    @IBAction func addBarrierButtonPressed(_ sender: Any) {
        addObject(VirtualObject.barrierObject()) { (result) in
            if result {
                self.statusViewController.showMessage("Barrier placed.\nDouble tap barrier to extend with additional ones.")
            }
        }
    }
    
    @IBOutlet weak var addTireButton: BlurButton!
    @IBAction func addTireButtonPressed(_ sender: Any) {
        addObject(VirtualObject.tireObject()) { (result) in
            if result {
                self.statusViewController.showMessage("Tire placed.\nDouble tap tire to stack additional ones.")
            }
        }
    }
    
    @IBOutlet weak var addConeButton: BlurButton!
    @IBAction func addConeButtonPressed(_ sender: Any) {
        addObject(VirtualObject.coneObject()) { (result) in
            if result {
                self.statusViewController.showMessage("Cone placed.\nDouble tap cone to line up additional ones.")
            }
        }
    }
    
    @IBOutlet weak var switchRaceButton: BlurButton!
    @IBAction func switchRaceButtonPressed(_ sender: Any) {
        switchRaceButton.isSelected = !switchRaceButton.isSelected
        raceMode = !raceMode
        if raceMode {
            statusViewController.showMessage("Racing mode activated")
        } else {
            statusViewController.showMessage("Racing mode deactivated")
        }
    }
    
    @IBOutlet weak var switchMuteSoundButton: BlurButton!
    @IBAction func switchMuteSoundButtonPressed(_ sender: Any) {
        switchMuteSoundButton.isSelected = !switchMuteSoundButton.isSelected
        soundMuted = !soundMuted
        if soundMuted {
            statusViewController.showMessage("Sound muted")
        } else {
            statusViewController.showMessage("Sound active")
        }
    }
   
    @IBOutlet weak var defenderCarGroup: UIStackView!
    @IBOutlet weak var avengerCarGroup: UIStackView!
    @IBOutlet weak var legoCarGroup: UIStackView!

    @IBOutlet weak var defenderCarButton: BlurButton!
    @IBAction func defenderCarButtonPressed(_ sender: Any) {
        defenderCarButton.isSelected = !defenderCarButton.isSelected
        if defenderCarButton.isSelected {
            resetDrivingMode()
            car = VirtualObject.defenderCar()
            car?.delegate = self
            fourWheelDrive = false
            startDrivingMode()
        } else {
            stopDrivingMode()
        }
        avengerCarButton.isSelected = false
        legoCarButton.isSelected = false
    }

    @IBOutlet weak var avengerCarButton: BlurButton!
    @IBAction func avengerCarButtonPressed(_ sender: Any) {
        avengerCarButton.isSelected = !avengerCarButton.isSelected
        if avengerCarButton.isSelected {
            resetDrivingMode()
            car = VirtualObject.avengerCar()
            car?.delegate = self
            fourWheelDrive = true
            startDrivingMode()
        } else {
            stopDrivingMode()
        }
        defenderCarButton.isSelected = false
        legoCarButton.isSelected = false
    }
    
    @IBOutlet weak var legoCarButton: BlurButton!
    @IBAction func legoCarButtonPressed(_ sender: Any) {
        legoCarButton.isSelected = !legoCarButton.isSelected
        if legoCarButton.isSelected {
            resetDrivingMode()
            car = VirtualObject.legoCar()
            car?.delegate = self
            fourWheelDrive = false
            startDrivingMode()
        } else {
            stopDrivingMode()
        }
        avengerCarButton.isSelected = false
        defenderCarButton.isSelected = false
    }
    
    @IBAction func removeObjectButtonPressed(_ sender: Any) {
        removeObjectButton.isSelected = !removeObjectButton.isSelected
        if removeObjectButton.isSelected {
            statusViewController.showMessage("Object removal mode activated.\nTap an object to remove it.")
        } else {
            statusViewController.showMessage("Object removal mode deactivated")
        }
    }
    
    @IBOutlet weak var actionButtonContainer: UIStackView!
    @IBOutlet weak var removeObjectButton: BlurButton!
    @IBOutlet weak var carButtonContainer: UIStackView!
    
    func initControls() {
        objectContainerLeftMarginConstraint.constant = 20
        actionContainerRightMarginConstraint.constant = 20
        leftAnalogJoystickLeftMarginConstraint.constant = -(leftAnalogJoystickWidthConstraint.constant + view.safeAreaInsets.left)
        leftAnalogJoystickBottomMarginConstraint.constant = -(leftAnalogJoystickWidthConstraint.constant + view.safeAreaInsets.left)
        rightAnalogJoystickRightMarginConstraint.constant = -(rightAnalogJoystickWidthConstraint.constant + view.safeAreaInsets.right)
        rightAnalogJoystickBottomMarginConstraint.constant = -(rightAnalogJoystickWidthConstraint.constant + view.safeAreaInsets.right)
        view.layoutIfNeeded()
    }
    
    func resetControls() {
        stopDrivingMode()
        defenderCarButton.isSelected = false
        avengerCarButton.isSelected = false
        legoCarButton.isSelected = false
    }
    
    func startDrivingMode() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = []
        session.run(configuration, options: [])
        
        carDrivingActive = true
       
        removeObjectButton.isSelected = false
        focusSquare.hide()
        
        objectContainerLeftMarginConstraint.constant = -(actionButtonContainer.bounds.width + 20 + view.safeAreaInsets.left)
        actionContainerRightMarginConstraint.constant = -(actionButtonContainer.bounds.width + 20 + view.safeAreaInsets.right)
        leftAnalogJoystickLeftMarginConstraint.constant = 10
        leftAnalogJoystickBottomMarginConstraint.constant = 10
        rightAnalogJoystickRightMarginConstraint.constant = 10
        rightAnalogJoystickBottomMarginConstraint.constant = 10
        UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseOut, animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
        
        if let car = car {
            addObject(car, { (result) in
                if result {
                    car.resetCar()
                    self.carSimulation = self.raceMode ? Car(car: car) : SimpleCar(car: car)
                    self.carSimulation?.setup(fourWheelDrive: self.fourWheelDrive)
                    self.statusViewController.showMessage("Driving mode started. Have fun!")
                } else {
                    self.statusViewController.showMessage("Cannot start driving mode.\nTry moving left or right.")
                }
            })
        }
        self.statusViewController.showMessage("Driving mode initializing...")
    }
    
    func stopDrivingMode() {
        guard carDrivingActive else {
            return
        }
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        session.run(configuration, options: [])
        
        resetDrivingMode()

        removeObjectButton.isSelected = false
        focusSquare.unhide()
        
        objectContainerLeftMarginConstraint.constant = 20
        actionContainerRightMarginConstraint.constant = 20
        leftAnalogJoystickLeftMarginConstraint.constant = -(leftAnalogJoystickWidthConstraint.constant + view.safeAreaInsets.left)
        leftAnalogJoystickBottomMarginConstraint.constant = -(leftAnalogJoystickWidthConstraint.constant + view.safeAreaInsets.left)
        rightAnalogJoystickRightMarginConstraint.constant = -(rightAnalogJoystickWidthConstraint.constant + view.safeAreaInsets.right)
        rightAnalogJoystickBottomMarginConstraint.constant = -(rightAnalogJoystickWidthConstraint.constant + view.safeAreaInsets.right)
        UIView.animate(withDuration: 0.5, delay: 0.0, options: .curveEaseOut, animations: {
            self.view.layoutIfNeeded()
        }, completion: nil)
        
        statusViewController.showMessage("Driving mode stopped")
    }
    
    func resetDrivingMode() {
        carSimulation = nil
        if let car = car {
            removeObject(car)
        }
        car = nil
        carDrivingActive = false
    }
    
    // MARK: Objects
    
    func addObject(_ object: VirtualObject, _ finishedHandler: ((Bool) -> Void)? = nil) {
        virtualObjectLoader.loadVirtualObject(object, loadedHandler: { [unowned self] loadedObject in
            DispatchQueue.main.async {
                let result = self.placeVirtualObject(loadedObject)
                if let finishedHandler = finishedHandler {
                    finishedHandler(result)
                }
            }
        })
    }
    
    func removeObject(_ object: VirtualObject) {
        virtualObjectLoader.removeVirtualObject(object)
    }
    
    func placeVirtualObject(_ virtualObject: VirtualObject) -> Bool {
        guard let cameraTransform = session.currentFrame?.camera.transform,
            let focusSquarePosition = focusSquare.lastPosition else {
                statusViewController.showMessage("Cannot place object\nTry moving left or right.")
                return false
        }
        
        virtualObject.setPosition(focusSquarePosition, relativeTo: cameraTransform, smoothMovement: false)
        rotateVirtualObjectToCamera(virtualObject)
        addVirtualObject(virtualObject)
        return true
    }
    
    func addVirtualObject(_ virtualObject: VirtualObject) {
        virtualObjectInteraction.selectedObject = virtualObject
        updateQueue.async {
            self.sceneView.scene.rootNode.addChildNode(virtualObject)
        }
    }
    
    func rotateVirtualObjectToCamera(_ virtualObject: VirtualObject) {
        // Rotate in relation to camera
        virtualObject.initRotate(camera: sceneView.session.currentFrame!.camera)
        /* Facing camera with transforms
        let rotate = simd_float4x4(SCNMatrix4MakeRotation(sceneView.session.currentFrame!.camera.eulerAngles.y, 0, 1, 0))
        if let lastHitTestResult = sceneView.lastHitTestResult {
            let rotateTransform = simd_mul(lastHitTestResult.worldTransform, rotate)
            virtualObject.transform = SCNMatrix4(rotateTransform)
        }*/
    }
    
    func hasObjects() -> Bool {
        return virtualObjectLoader.loadedObjects.count > 0
    }
    
    public func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        if let carSimulation = carSimulation,
            let car = car {
            let contactSpot = SCNNode()
            contactSpot.position = contact.contactPoint
            sceneView.scene.rootNode.addChildNode(contactSpot)
            if contact.nodeA === car {
                car.notifyContact(carSimulation: carSimulation, obstacle: contact.nodeB as! ObstacleVirtualObject, contactSpot: contactSpot, contactDirection: 1)
                carSimulation.notifyContact(contactDirection: 1, obstacle: contact.nodeB as! ObstacleVirtualObject)
            } else if contact.nodeB == car {
                car.notifyContact(carSimulation: carSimulation, obstacle: contact.nodeA as! ObstacleVirtualObject, contactSpot: contactSpot, contactDirection: 1)
                carSimulation.notifyContact(contactDirection: 1, obstacle: contact.nodeA as! ObstacleVirtualObject)
            }
        }
    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didUpdate contact: SCNPhysicsContact) {
        if let carSimulation = carSimulation,
            let car = car {
            if contact.nodeA === car {
                car.notifyContact(carSimulation: carSimulation, obstacle: contact.nodeB as! ObstacleVirtualObject, contactSpot: nil, contactDirection: 0)
                carSimulation.notifyContact(contactDirection: 0, obstacle: contact.nodeB as! ObstacleVirtualObject)
            } else if contact.nodeB == car {
                car.notifyContact(carSimulation: carSimulation, obstacle: contact.nodeA as! ObstacleVirtualObject, contactSpot: nil, contactDirection: 0)
                carSimulation.notifyContact(contactDirection: 0, obstacle: contact.nodeA as! ObstacleVirtualObject)
            }
        }
    }
    
    func physicsWorld(_ world: SCNPhysicsWorld, didEnd contact: SCNPhysicsContact) {
        if let carSimulation = carSimulation,
            let car = car {
            if contact.nodeA === car {
                car.notifyContact(carSimulation: carSimulation, obstacle: contact.nodeB as! ObstacleVirtualObject, contactSpot: nil, contactDirection: -1)
                carSimulation.notifyContact(contactDirection: -1, obstacle: contact.nodeB as! ObstacleVirtualObject)
            } else if contact.nodeB == car {
                car.notifyContact(carSimulation: carSimulation, obstacle: contact.nodeA as! ObstacleVirtualObject, contactSpot: nil, contactDirection: -1)
                carSimulation.notifyContact(contactDirection: -1, obstacle: contact.nodeA as! ObstacleVirtualObject)
            }
        }
    }
    
    // MARK: - UI Elements
    
    var focusSquare = FocusSquare()
    
    /// The view controller that displays the status and "restart experience" UI.
    lazy var statusViewController: StatusViewController = {
        return children.lazy.compactMap({ $0 as? StatusViewController }).first!
    }()
    
    // MARK: - ARKit Configuration Properties
    
    /// A type which manages gesture manipulation of virtual content in the scene.
    lazy var virtualObjectInteraction = VirtualObjectInteraction(sceneView: sceneView)
    
    /// Coordinates the loading and unloading of reference nodes for virtual objects.
    let virtualObjectLoader = VirtualObjectLoader()
    
    /// Marks if the AR experience is available for restart.
    var isRestartAvailable = true
    
    /// A serial queue used to coordinate adding or removing nodes from the scene.
    let updateQueue = DispatchQueue(label: "de.oklemenz.ARC.serialQueue")
    
    var screenCenter: CGPoint {
        let bounds = sceneView.bounds
        return CGPoint(x: bounds.midX, y: bounds.midY)
    }
    
    /// Convenience accessor for the session owned by ARSCNView.
    var session: ARSession {
        return sceneView.session
    }
    
    // MARK: - View Controller Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.delegate = self
        sceneView.session.delegate = self

        //sceneView.debugOptions = .showBoundingBoxes
        //sceneView.debugOptions = .showPhysicsShapes
        
        // Set up scene content.
        setupCamera()
        sceneView.scene.rootNode.addChildNode(focusSquare)
        sceneView.antialiasingMode = .multisampling4X

        sceneView.scene.physicsWorld.contactDelegate = self
       
        /*
         The `sceneView.automaticallyUpdatesLighting` option creates an
         ambient light source and modulates its intensity. This app
         instead modulates a global lighting environment map for use with
         physically based materials, so disable automatic lighting.
         */
        sceneView.automaticallyUpdatesLighting = false
        if let environmentMap = UIImage(named: "Models.scnassets/sharedImages/environment.jpg") {
            sceneView.scene.lightingEnvironment.contents = environmentMap
        }

        // Hook up status view controller callback(s).
        statusViewController.restartExperienceHandler = { [unowned self] in
            self.restartExperience()
        }
        
        virtualObjectInteraction.delegate = self
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            leftAnalogJoystickWidthConstraint.constant *= 2
            rightAnalogJoystickWidthConstraint.constant *= 2
            leftAnalogJoystick.backgroundSize *= 2
            rightAnalogJoystick.backgroundSize *= 2
            leftAnalogJoystick.buttonSize *= 2
            rightAnalogJoystick.buttonSize *= 2
        } else {
            leftAnalogJoystickWidthConstraint.constant *= 1.5
            rightAnalogJoystickWidthConstraint.constant *= 1.5
            leftAnalogJoystick.backgroundSize *= 1.5
            rightAnalogJoystick.backgroundSize *= 1.5
            leftAnalogJoystick.buttonSize *= 1.5
            rightAnalogJoystick.buttonSize *= 1.5
        }
    }

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		// Prevent the screen from being dimmed to avoid interuppting the AR experience.
		UIApplication.shared.isIdleTimerDisabled = true

        // Start the `ARSession`.
        resetTracking()
        
        initControls()
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)

        session.pause()
	}
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }

    // MARK: - Scene content setup

    func setupCamera() {
        guard let camera = sceneView.pointOfView?.camera else {
            fatalError("Expected a valid `pointOfView` from the scene.")
        }

        /*
         Enable HDR camera settings for the most realistic appearance
         with environmental lighting and physically based materials.
         */
        camera.wantsHDR = true
        camera.exposureOffset = -1
        camera.minimumExposure = -1
        camera.maximumExposure = 3
    }

    // MARK: - Session management
    
    /// Creates a new AR configuration to run on the `session`.
	func resetTracking() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
		session.run(configuration, options: [.resetTracking, .removeExistingAnchors])

        statusViewController.scheduleMessage("Find a surface to place an object", inSeconds: 7.5, messageType: .planeEstimation)
	}

    // MARK: - Focus Square

	func updateFocusSquare() {
        let isObjectVisible = virtualObjectLoader.loadedObjects.contains { object in
            return sceneView.isNode(object, insideFrustumOf: sceneView.pointOfView!)
        }
        
        if !isObjectVisible {
            statusViewController.scheduleMessage("Try moving left or right", inSeconds: 5.0, messageType: .focusSquare)
        }
        
        // We should always have a valid world position unless the sceen is just being initialized.
        guard let (worldPosition, planeAnchor, _) = sceneView.worldPosition(fromScreenPosition: screenCenter, objectPosition: focusSquare.lastPosition) else {
            updateQueue.async {
                self.focusSquare.state = .initializing
                self.sceneView.pointOfView?.addChildNode(self.focusSquare)
            }
            return
        }
        
        updateQueue.async {
            self.sceneView.scene.rootNode.addChildNode(self.focusSquare)
            let camera = self.session.currentFrame?.camera
            
            if let planeAnchor = planeAnchor {
                self.focusSquare.state = .planeDetected(anchorPosition: worldPosition, planeAnchor: planeAnchor, camera: camera)
            } else {
                self.focusSquare.state = .featuresDetected(anchorPosition: worldPosition, camera: camera)
            }
        }
        statusViewController.cancelScheduledMessage(for: .focusSquare)
	}
    
    func isInteractionMode() -> Bool {
        return !carDrivingActive
    }
    
    func isRemoveModeActive() -> Bool {
        return removeObjectButton.isSelected
    }
    
    func didTapObjectForRemove(object: VirtualObject) {
        removeObject(object.root)
        if !hasObjects() && removeObjectButton.isSelected {
            removeObjectButtonPressed(removeObjectButton!)
        }
    }
    
    func didTapObjectForClone(object: VirtualObject) {
        let camera = session.currentFrame?.camera
        if let shiftedClone = object.shiftedClone(direction: 1.0, camera: camera) {
            if !virtualObjectLoader.loadedObjects.contains(where: { (loadedObject) -> Bool in
                if loadedObject != object && type(of: loadedObject) == type(of: object) {
                    return objectsOverlap(o1: shiftedClone, o2: loadedObject)
                }
                return false
            }) {
                virtualObjectLoader.addVirtualObject(shiftedClone, contextObject: object)
                addVirtualObject(shiftedClone)
            } else {
                if let shiftedClone = object.shiftedClone(direction: -1.0, camera: camera) {
                    if !virtualObjectLoader.loadedObjects.contains(where: { (loadedObject) -> Bool in
                        if loadedObject != object && type(of: loadedObject) == type(of: object) {
                            return objectsOverlap(o1: shiftedClone, o2: loadedObject)
                        }
                        return false
                    }) {
                        virtualObjectLoader.addVirtualObject(shiftedClone, contextObject: object)
                        addVirtualObject(shiftedClone)
                    }
                }
            }
        }
    }
    
    func objectsOverlap(o1: VirtualObject, o2: VirtualObject) -> Bool {
        return sqrt(pow(o2.position.x - o1.position.x, 2) +
                    pow(o2.position.y - o1.position.y, 2) +
                    pow(o2.position.z - o1.position.z, 2)) < (o1.boundingBox.max.z - o1.boundingBox.min.z)
    }
    
	// MARK: - Error handling
    func displayErrorMessage(title: String, message: String) {
        // Blur the background.
        blurView.isHidden = false
        
        // Present an alert informing about the error that has occurred.
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
            alertController.dismiss(animated: true, completion: nil)
            self.blurView.isHidden = true
            self.resetTracking()
        }
        alertController.addAction(restartAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            alertController.dismiss(animated: true, completion: nil)
            self.blurView.isHidden = true
        }
        alertController.addAction(cancelAction)
        present(alertController, animated: true, completion: nil)
    }
}
