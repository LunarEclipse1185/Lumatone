//
//  Utils.swift
//  Lumatone
//
//  Created by SH BU on 2024/6/28.
//

import UIKit

/*
typealias vec = (CGFloat, CGFloat)

protocol Vec {
    func toVec() -> vec;
}

extension CGPoint: Vec {
    func toVec() -> vec { (x, y) }
}

extension CGSize: Vec {
    func toVec() -> vec { (width, height) }
}

func + (left: Vec, right: Vec) -> Vec {
    let l = left.toVec(), r = right.toVec()
    return CGPointMake(l.0 + r.0, l.1 + r.1) //screw you!
}
*/
 
func - (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPointMake(left.x - right.x, left.y - right.y)
}

prefix func - (point: CGPoint) -> CGPoint {
    return .zero - point
}

func CGPointDistanceSquared(_ from: CGPoint, _ to: CGPoint) -> CGFloat {
    return (from.x - to.x) * (from.x - to.x) + (from.y - to.y) * (from.y - to.y)
}
