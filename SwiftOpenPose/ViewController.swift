//
//  ViewController.swift
//  SwiftOpenPose
//
//  Created by tpomac2017 on 2017/11/14.
//  Copyright © 2017年 tpomac2017. All rights reserved.
//

import UIKit
import CoreML
import CoreMLHelpers
import Upsurge

class ViewController: UIViewController {
    
    let model = coco_pose_368()
    let com = Common()
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("========")
        if let image = UIImage(named: "person1.jpg"){
            print(measure(runJsonFile(image)).duration)
        }
//        if let image = UIImage(named: "hadou.jpg"){
//            print(measure(runCoreML(image)).duration)
//        }
        // saveTest()
    }
    
    func measure <T> (_ f: @autoclosure () -> T) -> (result: T, duration: String) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = f()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        return (result, "Elapsed time is \(timeElapsed) seconds.")
    }
    
    func runJsonFile(_ image: UIImage) {
        imageView.image = image
        
        let url = Bundle.main.url(forResource: "hoge", withExtension: "bin")!
        let text2 = try? String(contentsOf: url, encoding: .utf8)
        let personalData: Data = text2!.data(using: String.Encoding.utf8)!
        let json = try? JSONSerialization.jsonObject(with: personalData, options: [])
        
        if let array = json as? [Double] {
            
            var m: Array<Double> = Array()
            for i in 0..<array.count {
                m.append(Double(array[i]))
            }
            let mm = ValueArray(m)
            
            drewLine(mm)
        }
    }
    
    func runCoreML(_ image: UIImage) {
        
        if let pixelBuffer = image.pixelBuffer(width: com.ImageWidth, height: com.ImageHeight) {
            
            let startTime2 = CFAbsoluteTimeGetCurrent()
            if let prediction = try? model.prediction(image: pixelBuffer) {
                
                let timeElapsed2 = CFAbsoluteTimeGetCurrent() - startTime2
                print("Time elapsed for coreml: \(timeElapsed2) seconds")
                
                // view
                imageView.image = UIImage(pixelBuffer: pixelBuffer)
                
                let pred = prediction.net_output
                let length = pred.count
                
                let doublePtr =  pred.dataPointer.bindMemory(to: Double.self, capacity: length)
                let doubleBuffer = UnsafeBufferPointer(start: doublePtr, count: length)
                let mm = ValueArray<Double>(Array(doubleBuffer))
                
                drewLine(mm)
            }
        }
    }
    
    
    func drewLine(_ mm: ValueArray<Double>){
        
        let heatMapLen = 19*com.HeatRows*com.HeatColumns
        var heatMat = ValueArray<Double>(mm[0..<heatMapLen])
            .toMatrix(rows: 19, columns: com.HeatRows*com.HeatColumns)
        var pafMat  = ValueArray<Double>(mm[heatMapLen..<mm.count])
            .toMatrix(rows: 38, columns: com.HeatRows*com.HeatColumns)
        print(heatMat.count)
        print(pafMat.count)
        
        // Use of local variable 'estimate_pose' before its declaration
        //                print(pafMat)
        let startTime = CFAbsoluteTimeGetCurrent()
        let connections = com.estimate_pose(heatMat: &heatMat,pafMat: &pafMat)
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        print("Time elapsed for estimate_pose: \(timeElapsed) seconds")
        
        let image_h = com.ImageHeight
        let image_w = com.ImageWidth
        let heat_h = com.HeatColumns
        let heat_w = com.HeatRows
        
        let CocoPairsRender = com.CocoPairs[0..<com.CocoPairs.count-2]
        
        //      print(connections)
        for human in connections.values {
            for (part_idx, part) in human.enumerated() {
                
                // print(part.partIdx)
                if !CocoPairsRender.contains(part.partIdx){
                    continue
                }
                
                //                let center1 = CGPoint(x: Int(Int((Float(part.c1.0)) + 0.5) * image_w / heat_w), y: Int(Int((Float(part.c1.1) + 0.5)) * image_h / heat_h))
                //                let center2 = CGPoint(x: Int(Int((Float(part.c2.0)) + 0.5) * image_w / heat_w), y: Int(Int((Float(part.c2.1) + 0.5)) * image_h / heat_h))
                //
                
                let center1 = CGPoint(x: Int(Int(part.c1.0) * image_w / heat_w), y: Int(Int(part.c1.1) * image_h / heat_h))
                let center2 = CGPoint(x: Int(Int(part.c2.0) * image_w / heat_w), y: Int(Int(part.c2.1) * image_h / heat_h))
                
                // let test = CocoColors[part_idx]
                addLine(fromPoint: center1, toPoint: center2)
            }
        }
    }
    
    func addLine(fromPoint start: CGPoint, toPoint end:CGPoint) {
        let line = CAShapeLayer()
        let linePath = UIBezierPath()
        linePath.move(to: start)
        linePath.addLine(to: end)
        line.path = linePath.cgPath
        line.strokeColor = UIColor.red.cgColor
        line.lineWidth = 4
        line.lineJoin = kCALineJoinRound
        self.view.layer.addSublayer(line)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
