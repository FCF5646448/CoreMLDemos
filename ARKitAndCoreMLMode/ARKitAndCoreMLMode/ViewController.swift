//
//  ViewController.swift
//  ARKitAndCoreMLMode
//
//  Created by 冯才凡 on 2018/5/21.
//  Copyright © 2018年 冯才凡. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import Vision //对CoreML视觉的部分的再次封装

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView! //摄像头
    
    //拿到模型
    var resentModel = Resnet50()
    
    //点击之后的结果
    var hitTestResult:ARHitTestResult!
    
    //分析的结果
    var visionRequests:[VNRequest] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        // Create a new scene
        let scene = SCNScene() //named: "art.scnassets/ship.scn"
        
        // Set the scene to the view
        sceneView.scene = scene
        
        registerGR()
    }
    
    func registerGR(){
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        sceneView.addGestureRecognizer(tap)
    }
    
    @objc func tapAction(recognizer:UIGestureRecognizer){
        let scview = recognizer.view as! ARSCNView
        let touchLOcation = sceneView.center
        
        guard let currentFrame = scview.session.currentFrame else {return} //判别当前是否有像素
        let hisTestResults = scview.hitTest(touchLOcation, types: .featurePoint) //识别物件的特征点
        
        if hisTestResults.isEmpty {return}
        
        guard let hitTestResult = hisTestResults.first else {return} //获取到第一张图
        
        self.hitTestResult = hitTestResult
        
        let pixelBuffer = currentFrame.capturedImage //将拿到的图片转成像素
        
        performVisionRequest(pixelBuffer)
        
    }
    
    func performVisionRequest(_ pixelBuffer:CVPixelBuffer){
        guard let visionM = try? VNCoreMLModel(for: resentModel.model) else {return }
        let request = VNCoreMLRequest.init(model: visionM) { (request, error) in
           
            if error != nil { return }
            
            guard let observations = request.results else {return} //拿出结果
            
            let observation = observations.first as! VNClassificationObservation //把结果中的第一位拿出来进行分析
            print("Name: \(observation.identifier) and confidence: \(observation.confidence)")
            
            DispatchQueue.main.async {
                self.displayPrediction(observation.identifier)
            }
        }
        
        request.imageCropAndScaleOption = .centerCrop //进行喂食
        
        visionRequests = [request]  //
        
        let imageRequest = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: .upMirrored, options: [:]) //镜像
        
        DispatchQueue.global().async {
            try! imageRequest.perform(self.visionRequests) //处理所有的结果
        }
    }
    
    //展示结果
    func displayPrediction(_ text:String){
        let node = createText(text)
        node.position = SCNVector3(hitTestResult.worldTransform.columns.3.x,
                                   hitTestResult.worldTransform.columns.3.y,
                                   hitTestResult.worldTransform.columns.3.z)
        
        sceneView.scene.rootNode.addChildNode(node)
    }
    
    //制作AR图标跟底座
    func createText(_ text:String)->SCNNode {
        let parantNode = SCNNode()
        
        //底座
        let sphere = SCNSphere(radius: 0.01) //1cm 小球
        
        let sphereMaterial = SCNMaterial()
        sphereMaterial.diffuse.contents = UIColor.orange
        sphere.firstMaterial = sphereMaterial
        
        let sphereNode = SCNNode(geometry: sphere) //创建球状节点
        
        //文字
        let textGeo = SCNText(string: text, extrusionDepth: 0)
        textGeo.alignmentMode = kCAAlignmentCenter
        textGeo.firstMaterial?.diffuse.contents = UIColor.orange
        textGeo.firstMaterial?.specular.contents = UIColor.white
        textGeo.firstMaterial?.isDoubleSided = true
        textGeo.font = UIFont(name: "Futura", size: 0.15)
        
        let textNode = SCNNode(geometry: textGeo)
        textNode.scale = SCNVector3Make(0.2, 0.2, 0.2)
        
        parantNode.addChildNode(sphereNode)
        parantNode.addChildNode(textNode)
        
        return parantNode
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
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
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
