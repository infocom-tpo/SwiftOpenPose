//
//  UIViewController.swift
//  openposeTest5
//
//  Created by tpomac2017 on 2017/11/13.
//  Copyright © 2017年 tpomac2017. All rights reserved.
//

import Foundation

import UIKit
import Upsurge
import IteratorTools

extension NSMutableArray {
    func asArray<T>() -> [T]? {
        return self as NSArray as? [T] // Warning: Cast from 'NSArray' to unrelated type '[T]' always fails
    }
}
extension CGPoint {
    init(_ x: CGFloat, _ y: CGFloat) {
        self.x = x
        self.y = y
    }
}

struct Connection {
    var score: Double
    var c1: (Int, Int)
    var c2: (Int, Int)
    var idx: (Int, Int)
    var partIdx: CGPoint
    var uPartIdx: [String]
    
    init(score: Double,c1: (Int, Int),c2: (Int, Int),idx: (Int, Int),partIdx: CGPoint,uPartIdx: [String]) {
        self.score = score
        self.c1 = c1
        self.c2 = c2
        self.idx = idx
        self.partIdx = partIdx
        self.uPartIdx = uPartIdx
    }
}

class Common {
    
    let opencv = OpenCVWrapper()
    
    let ImageWidth = 368
    let ImageHeight = 368
    let HeatRows = 46
    let HeatColumns = 46
    let CocoPairs = [
        CGPoint(1, 2), CGPoint(1, 5), CGPoint(2, 3), CGPoint(3, 4), CGPoint(5, 6), CGPoint(6, 7), CGPoint(1, 8), CGPoint(8, 9), CGPoint(9, 10), CGPoint(1, 11),
        CGPoint(11, 12), CGPoint(12, 13), CGPoint(1, 0), CGPoint(0, 14), CGPoint(14, 16), CGPoint(0, 15), CGPoint(15, 17), CGPoint(2, 16), CGPoint(5, 17)
    ] // = 19
    
    let CocoPairsNetwork = [
        CGPoint(12, 13), CGPoint(20, 21), CGPoint(14, 15), CGPoint(16, 17), CGPoint(22, 23), CGPoint(24, 25), CGPoint(0, 1), CGPoint(2, 3), CGPoint(4, 5),
        CGPoint(6, 7), CGPoint(8, 9), CGPoint(10, 11), CGPoint(28, 29), CGPoint(30, 31), CGPoint(34, 35), CGPoint(32, 33), CGPoint(36, 37), CGPoint(18, 19), CGPoint(26, 27)
    ]  // = 19
    
    let CocoColors = [[255, 0, 0], [255, 85, 0], [255, 170, 0], [255, 255, 0], [170, 255, 0], [85, 255, 0], [0, 255, 0],
                      [0, 255, 85], [0, 255, 170], [0, 255, 255], [0, 170, 255], [0, 85, 255], [0, 0, 255], [85, 0, 255],
                      [170, 0, 255], [255, 0, 255], [255, 0, 170], [255, 0, 85]]
    
    
    let NMS_Threshold = 0.05
    let InterMinAbove_Threshold = 4
    let Inter_Threashold = 0.05
    let Min_Subset_Cnt = 3
    let Min_Subset_Score = 0.4
    let Max_Human = 96
    
    let model = coco_pose_368()
    
    func estimate_pose (heatMat: inout Matrix<Double>,pafMat: inout Matrix<Double>) -> [Int: [Connection]] {
        
        let startTime3 = CFAbsoluteTimeGetCurrent()
        
        // benchmark 0.2
        //        let heatMat2 = Surge.transpose(heatMat)
        let b = ValueArray<Double>((0..<heatMat.rows).map({ min(heatMat.row($0)) }))
            .toColumnMatrix().tile(1,heatMat.columns)
        
        heatMat = heatMat - b
        
        // benchmark 0.4
        // 2116(46x46) 毎に 区切って最小値を求める
        let q = ValueArray<Double>(capacity: heatMat.elements.count)
        
//        for i in 0..<heatMat.rows {
//            let a = ValueArray<Double>(heatMat.row(i)).toMatrix(rows: ImageRows, columns: ImageColumns)
//            let b = ValueArray<Double>((0..<a.rows).map({ min(a.row($0)) })).toColumnMatrix().tile(1,ImageColumns)
//            q.append(contentsOf: (a - b).elements)
//        }
//        heatMat = q.toMatrix(rows: 19, columns: ImageRows*ImageColumns)
//
        
        for i in 0..<heatMat.rows {
            let a = ValueArray<Double>(heatMat.row(i)).toMatrix(rows: HeatRows, columns: HeatColumns)
            let b = ValueArray<Double>((0..<a.rows).map({ min(a.row($0)) })).toColumnMatrix().tile(1,HeatColumns)
            q.append(contentsOf: (a - b).elements)
        }
        heatMat = q.toMatrix(rows: 19, columns: HeatRows*HeatColumns)
        
        let timeElapsed3 = CFAbsoluteTimeGetCurrent() - startTime3
        print("Time elapsed for others: \(timeElapsed3) seconds")
        
        print(sum(heatMat.elements)) // 810.501374994155
        var _NMS_Threshold = max(mean(heatMat.elements) * 4.0, NMS_Threshold)
        _NMS_Threshold = min(_NMS_Threshold, 0.3)
        var coords = [[[Int]]]()
        
//        print("============")
//        print(heatMat2.elements.count) // 40204
//        print(heatMat2.columns) // 2116
//        print(heatMat2.rows) // 19
//        print(_NMS_Threshold)
        for i in 0..<heatMat.rows-1 {
            let plain = Array<Double>(heatMat.row(i))
            let nms = non_max_suppression_pointer(plain, 5, _NMS_Threshold)
            
            let c = nms.enumerated().filter{ $0.1 > _NMS_Threshold }.map { x in
                return  [ Int(x.0 / HeatRows) , Int(x.0 % HeatRows) ]
            }
            coords.append(c)
        }
        
        // result heatMat parts
        // 単体のみ動作確認、後程複数人のチェック予定
//        print(coords)
//
//        var connection_temp = [Connection]()
        let startTime2 = CFAbsoluteTimeGetCurrent()
        
        var conn = [[Connection]]()
        for (idx, paf) in zip(CocoPairs, CocoPairsNetwork) {
            let idx1 = Int(idx.x)
            let idx2 = Int(idx.y)
            let paf_x_idx = Int(paf.x)
            let paf_y_idx = Int(paf.y)
            
            let pafMatX = ValueArray<Double>(pafMat.row(paf_x_idx))
            let pafMatY = ValueArray<Double>(pafMat.row(paf_y_idx))
            
            let connection = estimate_pose_pair(coords, idx1, idx2, pafMatX, pafMatY)
            conn.append(connection)
        }
        
        let timeElapsed2 = CFAbsoluteTimeGetCurrent() - startTime2
        print("Time elapsed for estimate_pose_pair: \(timeElapsed2) seconds")
        
        var connection_by_human = [Int: [Connection]]()
        // var connection_by_human = [[Connection]]()
        for (idx, c) in conn.enumerated(){
            connection_by_human[idx] = [Connection]()
            connection_by_human[idx]!.append(contentsOf: c)
        }
        
        var connection_index_tmp = conn.indices.map {$0}
        // print(connection_index_tmp)
        
        var no_merge_cache = [Int: [Int]]()
        for idx in conn.indices {
            no_merge_cache[idx] = []
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        
        while true {
            var is_merged = false
            
            for idx in connection_index_tmp.combinations(length: 2){
                let k1 = idx[0]
                let k2 = idx[1]
                
                // print(String(format: "%d - %d",k1 ,k2))
                if k1 == k2{
                    continue
                }
                if no_merge_cache[k1]!.contains(k2) {
                    continue
                }
                // dictionaryの順序なしで処理がうまくいくか？
                for prd in product(connection_by_human[k1]!,connection_by_human[k2]!){
                    let c1 = prd[0]
                    let c2 = prd[1]
                    let c = Array<String>(Set(c1.uPartIdx)) + Array<String>(Set(c2.uPartIdx))
                    if c.count > Set(c).count {
                        is_merged = true
                        if let num = connection_index_tmp.index(of: k2) {
                            connection_by_human[k1]!.append(contentsOf: connection_by_human[k2]!)
                            connection_by_human.removeValue(forKey: k2)
                            connection_index_tmp.remove(at: num)
                            break;
                        }
                    }
                }
                if is_merged {
                    no_merge_cache[k1] = []
                    break
                } else {
                    no_merge_cache[k1]!.append(k2)
                }
            }
            
            if !is_merged {
                break
            }
        }
        
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        print("Time elapsed for roop: \(timeElapsed) seconds")
        
        // 未実装な処理
        
        //  connection_by_human = {k: v for (k, v) in connection_by_human.items() if len(v) >= Min_Subset_Cnt}
        //  # reject by subset max score
        //  connection_by_human = {k: v for (k, v) in connection_by_human.items() if max([ii['score'] for ii in v]) >= Min_Subset_Score}
        
//        print(connection_by_human)
        return connection_by_human
        
    }
    
    func non_max_suppression_pointer(_ np_input: [Double],_
        window_size: Int32, _ threshold: Double) -> [Double] {
        var input : [Double] = np_input
        // cpp
        opencv.maximum_filter_pointer(&input
            ,size: Int32(input.count)
            , window_size: window_size
            ,threshold: threshold)
        return input
    }
    
    func get_score(_ x1 : Int,_ y1: Int,_ x2: Int,_ y2: Int,_ pafMatX: ValueArray<Double>,_ pafMatY: ValueArray<Double>) -> (Double,Int) {
        let __num_inter = 10
        let __num_inter_f = Double(__num_inter)
        let dx = Double(x2 - x1)
        let dy = Double(y2 - y1)
        let normVec = sqrt(pow(dx,2) + pow(dy,2))
        
        if normVec < 1e-4 {
            return (0.0, 0)
        }
        let vx = dx / normVec
        let vy = dy / normVec
        var xs : [Double]
        
        if x1 == x2 {
            xs = Array<Double>(repeating: Double(x1) , count: __num_inter)
        } else {
            xs = stride(from: Double(x1), to: Double(x2), by: Double(dx / __num_inter_f)).map {$0}
        }
        var ys : [Double]
        if y1 == y2 {
            ys = Array<Double>(repeating: Double(y1) , count: __num_inter)
        } else {
            ys = stride(from: Double(y1), to: Double(y2), by: Double(dy / __num_inter_f)).map {$0}
        }
        let xs2 = xs.map{ Int($0+0.5) }
        let ys2 = ys.map{ Int($0+0.5) }
        
        var pafXs : [Double] = Array(repeating: 0.0 , count: __num_inter)
        var pafYs : [Double] = Array(repeating: 0.0 , count: __num_inter)
        for (idx, (mx, my)) in zip(xs2, ys2).enumerated(){
            pafXs[idx] = pafMatX[my*HeatRows+mx]
            pafYs[idx] = pafMatY[my*HeatRows+mx]
        }
        
        let local_scores = pafXs * vx + pafYs * vy
        
        var res = local_scores.filter({$0 > Inter_Threashold})
        if (res.count > 0){
            res[0] = 0.0
        }
        return (sum(res), res.count)
    }
    func estimate_pose_pair(_ coords : [[[Int]]] ,
                            _ partIdx1: Int,_ partIdx2: Int,
                            _ pafMatX: ValueArray<Double>, _ pafMatY: ValueArray<Double>) -> [Connection] {
        
        let peak_coord1 = coords[partIdx1]
        let peak_coord2 = coords[partIdx2]
        
        var connection_temp = [Connection]()
        var cnt = 0
        for (idx1, x) in peak_coord1.enumerated() {
            let x1 = x[1]
            let y1 = x[0]
            for (idx2, xx) in peak_coord2.enumerated() {
                let x2 = xx[1]
                let y2 = xx[0]
                let (score, count) = get_score(x1, y1, x2, y2, pafMatX, pafMatY)
                cnt += 1
                if count < InterMinAbove_Threshold || score <= 0.0 {
                    continue
                }
                
                connection_temp.append(Connection(
                    score: score,
                    c1: (x1, y1),
                    c2: (x2, y2),
                    idx: (idx1, idx2),
                    partIdx: CGPoint(x: partIdx1,y: partIdx2),
                    uPartIdx: [String(format: "%d-%d-%d", x1, y1, partIdx1) , String(format: "%d-%d-%d", x2, y2, partIdx2)]
                ))
            }
        }
        
        // 複数人対応と複数スコアのカット
        var connection = [Connection]()
        var used_idx1 = [Int]()
        var used_idx2 = [Int]()
        connection_temp.sorted{ $0.score > $1.score }.forEach { conn in
            
            if used_idx1.contains(conn.idx.0) || used_idx2.contains(conn.idx.1) {
                return
            }
            connection.append(conn)
            used_idx1.append(conn.idx.0)
            used_idx2.append(conn.idx.1)
        }
        
        return connection
    }
}

