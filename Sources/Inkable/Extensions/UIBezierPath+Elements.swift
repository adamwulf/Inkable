//
//  UIBezierPath+Elements.swift
//  Inkable
//
//  Created by Adam Wulf on 4/4/21.
//

import UIKit

public extension UIBezierPath {
    enum Element: Equatable, CustomDebugStringConvertible {
        case moveTo(point: Polyline.Point)
        case lineTo(point: Polyline.Point)
        case curveTo(point: Polyline.Point, ctrl1: CGPoint, ctrl2: CGPoint)

        // MARK: CustomDebugStringConvertible

        public var debugDescription: String {
            switch self {
            case .moveTo(let point):
                return "moveTo(\(point.location))"
            case .lineTo(let point):
                return "lineTo(\(point.location))"
            case .curveTo(let point, let ctrl1, let ctrl2):
                return "curveTo(\(point.location), \(ctrl1), \(ctrl2))"
            }
        }

        // MARK: Equatable

        public static func == (lhs: UIBezierPath.Element, rhs: UIBezierPath.Element) -> Bool {
            if case let .moveTo(point: lpoint) = lhs,
               case let .moveTo(point: rpoint) = rhs {
                return lpoint.touchPoint == rpoint.touchPoint
            }
            if case let .lineTo(point: lpoint) = lhs,
               case let .lineTo(point: rpoint) = rhs {
                return lpoint.touchPoint == rpoint.touchPoint
            }
            if case let .curveTo(point: lpoint, ctrl1: lctrl1, ctrl2: lctrl2) = lhs,
               case let .curveTo(point: rpoint, ctrl1: rctrl1, ctrl2: rctrl2) = rhs {
                return lpoint.touchPoint == rpoint.touchPoint && lctrl1 == rctrl1 && lctrl2 == rctrl2
            }
            return false
        }
    }
}

public extension UIBezierPath {
    func append(_ element: UIBezierPath.Element) {
        switch element {
        case .moveTo(let point):
            move(to: point.location)
        case .lineTo(let point):
            assert(elementCount > 0, "must contain a moveTo")
            addLine(to: point.location)
        case .curveTo(let point, let ctrl1, let ctrl2):
            assert(elementCount > 0, "must contain a moveTo")
            addCurve(to: point.location, controlPoint1: ctrl1, controlPoint2: ctrl2)
        }
    }
}
