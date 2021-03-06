//
//  ViewController.swift
//  jumpARun
//
//  Created by Sergej Nawalnew on 28.11.17.
//  Copyright © 2017 Sergej Nawalnew. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import GameplayKit

enum FunctionMode {
    case none
    case addField
    case placeObject(String)
    case measure
}


class ViewController: UIViewController {

    @IBOutlet var sceneView: ARSCNView!
    
    @IBOutlet weak var trackingInfo: UILabel!
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var fieldButton: UIButton!
    
    var currentMode: FunctionMode = .none
    var planeDetectionActive = true
    var fieldNode = SCNNode()
    
    @IBAction func fieldButtonTapped(_ sender: Any) {
        // configureWorldBottom()
        // currentMode = .placeObject("Models.scnassets/box/box.scn")
        currentMode = .addField
    }
    
    var objects: [SCNNode] = []
    var measuringNodes: [SCNNode] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        // Set the view's delegate
//        sceneView.delegate = self
//
//        // Show statistics such as fps and timing information
//        sceneView.showsStatistics = true
//
//        // Create a new scene
//        let scene = SCNScene(named: "art.scnassets/ship.scn")!
//
//        // Set the scene to the view
//        sceneView.scene = scene
        
        
        
        trackingInfo.text = ""
        messageLabel.text = ""
        runSession()
     
    }
    
    
    func removeAllObjects() {
        for object in objects {
            object.removeFromParentNode()
        }
        
        objects = []
    }
    
    
    func runSession() {
        sceneView.delegate = self
        let configuration = ARWorldTrackingConfiguration()
        
        // Plane detection aushängen wenn eine gefunden
        if planeDetectionActive {
            // removeAllObjects()
            configuration.planeDetection = .horizontal
        }
        
        configuration.isLightEstimationEnabled = true
        sceneView.session.run(configuration)
        #if DEBUG
            sceneView.debugOptions = ARSCNDebugOptions.showFeaturePoints
        #endif
    }
    
    // HIT TEST
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let hit = sceneView.hitTest(viewCenter, types: [.existingPlaneUsingExtent]).first {
            let myAnchor = ARAnchor(transform: hit.worldTransform)
            sceneView.session.add(anchor: myAnchor)
            
            return
        } else if let hit = sceneView.hitTest(viewCenter, types: [.featurePoint]).last {
            sceneView.session.add(anchor: ARAnchor(transform: hit.worldTransform))
            return
        }
    }
    

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/

    
    
    func updateTrackingInfo() {
        
        guard let frame = sceneView.session.currentFrame else {
            return
        }
        switch frame.camera.trackingState {
        case .limited(let reason):
            switch reason {
            case .excessiveMotion:
                trackingInfo.text = "Limited Tracking: Excessive Motion"
            case .insufficientFeatures:
                trackingInfo.text = "Limited Tracking: Insufficient Details"
            default:
                trackingInfo.text = "Limited Tracking"
            }
        default:
            trackingInfo.text = ""
        }
        
        guard let lightEstimate = frame.lightEstimate?.ambientIntensity else {
            return
        }
        
        if lightEstimate < 100 {
            trackingInfo.text = "Limited Tracking: Too Dark"
        }
    }
    
    // Create Game Field
    private func configureWorldBottom() {
        let bottomPlane = SCNBox(width: 5, height: 0.5, length: 5, chamferRadius: 0)
        
        let material = SCNMaterial()
        material.diffuse.contents = UIColor(white: 1.0, alpha: 1.0)
        bottomPlane.materials = [material]
        
        let bottomNode = SCNNode(geometry: bottomPlane)
        bottomNode.position = SCNVector3(x: 0, y: 1, z: 0)
        
//        let physicsBody = SCNPhysicsBody.static()
//        physicsBody.categoryBitMask = CollisionTypes.bottom.rawValue
//        physicsBody.contactTestBitMask = CollisionTypes.shape.rawValue
//        bottomNode.physicsBody = physicsBody
        
        self.sceneView.scene.rootNode.addChildNode(bottomNode)
//        self.sceneView.scene.physicsWorld.contactDelegate = self
    }
    
    // Create Random Objects on Node
    // HELP
    @objc func createRandomObstacles() {
        let pos = fieldNode.worldPosition
        let fieldPlane = fieldNode.geometry as! SCNBox
        
      
        let obstacleHeight = CGFloat(0.1)
        let obstacleWidth = CGFloat(0.1)
        let obstacleLength = CGFloat(0.1)
        
        
        // Größe des Spielfeldes
        let width = Float(fieldPlane.width)
         // print(String(width) + " Width")
        let height = Float(fieldPlane.height)
        let length = Float(fieldPlane.length)
        // print(String(height) + " Height")
        
        
        
        // Spielfeld minimum größe
//        let minX = pos.x
//        let minZ = pos.z
//        let minY = pos.y
        
        
        let maxX = (Float(GKRandomSource.sharedRandom().nextInt(upperBound: 100))/100)-0.25
        let maxZ = pos.z + length/2
        let maxY = pos.y + height
 
        
        
        
        // Create Object
        let obstacle = createRandomObstacleNode(center: vector_float3(maxX, maxY, maxZ), width: obstacleWidth, height: obstacleHeight, length: obstacleLength )
        self.objects.append(obstacle)
        sceneView.scene.rootNode.addChildNode(obstacle)
        
        // Move Objects
        
        let moveBy = SCNAction.moveBy(x: 0, y: 0, z: -1, duration: 2)
        obstacle.runAction(moveBy)
        
    }
    
    // Create Player
    @objc func createPlayerFigure() {
        let pos = fieldNode.worldPosition
        let fieldPlane = fieldNode.geometry as! SCNBox
        
        
        let playerHeight = CGFloat(0.25)
        let playerWidth = CGFloat(0.1)
        let playerLength = CGFloat(0.1)
        
        
        // Größe des Spielfeldes
        let width = Float(fieldPlane.width)
        // print(String(width) + " Width")
        let height = Float(fieldPlane.height)
        let length = Float(fieldPlane.length)
        // print(String(height) + " Height")
        
        
        
        // Spielfeld minimum größe
        //        let minX = pos.x
        //        let minZ = pos.z
        //        let minY = pos.y
        
        
        let posX = pos.x - (width-1)
        
        let posY = pos.y + height
        
        let posZ = pos.z - (length-1)
        
        
        
        
        
        
        // Create Player Object
        let player = createPlayerFigureNode(center: vector_float3(posX, posY, posZ), width: playerWidth, height: playerHeight, length: playerLength )
        self.objects.append(player)
        sceneView.scene.rootNode.addChildNode(player)
        
        
    }
    
    func playerJumpFunction(){
        let playerObject = self.fieldNode.childNode(withName: "player", recursively: false)
        // move up 20
        let jumpUpAction = SCNAction.moveBy(x: 2, y:2, z:0, duration:0.2)
        // move down 20
        let jumpDownAction = SCNAction.moveBy(x: 2, y:-2, z:0, duration:0.2)
        // sequence of move yup then down
        let jumpSequence = SCNAction.sequence([jumpUpAction, jumpDownAction])
        
        
        
        // make player run sequence
        playerObject?.runAction(jumpSequence)
        print("test")
    }
    
}






// Extend ViewController AR
extension ViewController: ARSCNViewDelegate {
    
    
    func session(_ session: ARSession, didFailWithError error: Error) {
         // Present an error message to the user
        showMessage(error.localizedDescription, label: messageLabel, seconds: 2)
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
         // Inform the user that the session has been interrupted, for example, by presenting an overlay
        showMessage("Session interuppted", label: messageLabel, seconds: 2)
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        showMessage("Session resumed", label: messageLabel, seconds: 2)
        removeAllObjects()
        runSession()
        
    }
    
    
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        DispatchQueue.main.async {
            self.updateTrackingInfo()
        }
        
    }
    
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
        DispatchQueue.main.async {
            if let planeAnchor = anchor as? ARPlaneAnchor {
                
                #if DEBUG
                    let planeNode = createPlaneNode(center: planeAnchor.center, extent: planeAnchor.extent)
                    node.addChildNode(planeNode)
                    
                    self.planeDetectionActive = false
                    self.runSession()
                    
                    self.fieldNode = createFieldNode(center: planeAnchor.center)
                    self.objects.append(self.fieldNode)
                    node.addChildNode(self.fieldNode)
                    
                    // Create Random Obstacles every 2 seconds
                    let date = Date().addingTimeInterval(2)
                    let timer = Timer(fireAt: date, interval: 2, target: self, selector: #selector(self.createRandomObstacles), userInfo: nil, repeats: true)
                    RunLoop.main.add(timer, forMode: RunLoopMode.commonModes)
                    
                    
                    // Create Player Objects
                    self.createPlayerFigure()
                    
                    
                    
                #endif
                
                // ON CLICK
            } else {
                
                // Create a new scene
//                let cameraPosition = SCNVector3(
//                    /* At this moment you could be sure, that camera properly oriented in world coordinates */
//                    anchor.transform.columns.3.x,
//                    anchor.transform.columns.3.y,
//                    anchor.transform.columns.3.z
//                )
                
                self.playerJumpFunction()
                
//                let fieldNode = createFieldNode2(center: vector_float3(anchor.transform.columns.3.x,anchor.transform.columns.3.y,anchor.transform.columns.3.z))
//
//                print(anchor.transform.columns.3.y)
//                print(anchor.transform.columns.3.x)
//                print(anchor.transform.columns.3.z)
//
//                self.objects.append(fieldNode)
//                node.addChildNode(fieldNode)
                
                // anchor.transform.columns.3.x
                
                
                
//                switch self.currentMode {
//                case .none:
//                    break
//                case .addField:
//                    let fieldNode = createFieldNode(center: planeAnchor.center)
//                    self.objects.append(fieldNode)
//                    node.addChildNode(fieldNode)
//                    break
//
//                case .placeObject(let name):
                
                    
//                    let fieldNode = createFieldNode(center: planeAnchor.center, extent: planeAnchor.extent)
//                    node.addChildNode(fieldNode)
//
                    
//                    let modelClone = SCNScene(named: name)!.rootNode.clone()
//
//                    self.objects.append(modelClone)
//                    node.addChildNode(modelClone)
//                case .measure:
//                    let spehereNode = createSphereNode(radius: 0.02)
//                    self.objects.append(spehereNode)
//                    node.addChildNode(spehereNode)
//                    self.measuringNodes.append(node)
//                }
            }
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        DispatchQueue.main.async {
           // if let planeAnchor = anchor as? ARPlaneAnchor {
                // updatePlaneNode(node.childNodes[0], center: planeAnchor.center, extent: planeAnchor.extent)
           // }
        }
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRemove node: SCNNode, for anchor: ARAnchor) {
        guard anchor is ARPlaneAnchor else { return }
        removeChildren(inNode: node)
    }
    
}
