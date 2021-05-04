//
//  CGPoint+Extensions.swift
//  Inkable
//
//  Created by Adam Wulf on 8/22/20.
//

import UIKit

extension CGPoint {
    static func * (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        return CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
    }
    static func * (lhs: CGFloat, rhs: CGPoint) -> CGPoint {
        return rhs * lhs
    }
    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
}
