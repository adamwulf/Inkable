//
//  AntigrainSmoother.swift
//  Inkable
//
//  Created by Adam Wulf on 10/31/20.
//

import Foundation
import UIKit
/// A smoother that implements the Antigrain algorithm for converting polylines to smooth Bézier curves.
///
/// This algorithm is based on the method described at [Elvenprogrammer's Bezier Interpolation](http://www.elvenprogrammer.org/projects/bezier/reference/index.html).
/// It provides a simple and efficient way to create smooth curves that pass through all points of the original polyline.
///
/// The smoothness of the curve can be adjusted using the `smoothFactor` parameter.
open class AntigrainSmoother: Smoother {

    /// The factor that determines the smoothness of the resulting curve.
    ///
    /// Values should be in the range [0...1]. A value closer to 1 results in a smoother curve,
    /// while a value closer to 0 produces a curve that more closely follows the original polyline.
    let smoothFactor: CGFloat

    /// Initializes a new AntigrainSmoother with the specified smooth factor.
    ///
    /// - Parameter smoothFactor: The smoothness factor for the curve. Defaults to 0.7.
    ///   Valid values range from 0 to 1, inclusive.
    ///   - A value of 0 produces a curve that closely follows the original polyline, with sharp corners.
    ///   - A value of 1 creates the smoothest possible curve, which may deviate significantly from the original points.
    ///   - Values between 0 and 1 provide a balance between smoothness and fidelity to the original shape.
    ///   - Values outside the [0, 1] range are not recommended as they may produce unexpected results.
    public init(smoothFactor: CGFloat = 0.7) {
        self.smoothFactor = smoothFactor
    }

    public func element(for line: Polyline, at elementIndex: Int) -> BezierElementStream.Element {
        assert(elementIndex >= 0 && elementIndex <= maxIndex(for: line))

        if elementIndex == 0 {
            return .moveTo(point: line.points[0])
        }

        if elementIndex == 1 {
            return Self.newCurve(smoothFactor: smoothFactor,
                                 p1: line.points[0].location,
                                 p2: line.points[1],
                                 p3: line.points[2].location)
        }

        if line.isComplete && elementIndex == maxIndex(for: line) {
            return Self.newCurve(smoothFactor: smoothFactor,
                                 p0: line.points[elementIndex - 2].location,
                                 p1: line.points[elementIndex - 1].location,
                                 p2: line.points[elementIndex],
                                 p3: line.points[elementIndex].location)
        }

        return Self.newCurve(smoothFactor: smoothFactor,
                             p0: line.points[elementIndex - 2].location,
                             p1: line.points[elementIndex - 1].location,
                             p2: line.points[elementIndex],
                             p3: line.points[elementIndex + 1].location)
    }

    public func maxIndex(for line: Polyline) -> Int {
        let lastIndex = line.points.count - 1
        return Swift.max(0, lastIndex - 1) + (line.points.count > 2 && line.isComplete ? 1 : 0)
    }

    public func elementIndexes(for line: Polyline, at lineIndexes: MinMaxIndex, with bezier: BezierElementStream.Bezier) -> MinMaxIndex {
        var curveIndexes = MinMaxIndex()

        for index in lineIndexes {
            elementIndexes(for: line, at: index, with: bezier, into: &curveIndexes)
        }

        return curveIndexes
    }

    public func elementIndexes(for line: Polyline, at lineIndex: Int, with bezier: BezierElementStream.Bezier) -> MinMaxIndex {
        var ret = MinMaxIndex()
        elementIndexes(for: line, at: lineIndex, with: bezier, into: &ret)
        return ret
    }

    // Below are the examples of input indexes, and which smoothed elements that point index affects
    // 0 => 2, 1, 0
    // 1 => 3, 2, 1, 0
    // 2 => 4, 3, 2, 1
    // 3 => 5, 4, 3, 2
    // 4 => 6, 5, 4, 3
    // 5 => 7, 6, 5, 4
    // 6 => 8, 7, 6, 5
    // 7 => 9, 8, 7, 6
    private func elementIndexes(for line: Polyline, at lineIndex: Int, with bezier: BezierElementStream.Bezier, into indexes: inout MinMaxIndex) {
        guard lineIndex >= 0 else {
            return
        }
        let max = maxIndex(for: line)

        if lineIndex > 1,
           (lineIndex - 1 <= max) || (lineIndex - 1 < bezier.elements.count) {
            indexes.insert(lineIndex - 1)
        }
        if (lineIndex <= max) || (lineIndex < bezier.elements.count) {
            indexes.insert(lineIndex)
        }
        if (lineIndex + 1 <= max) || (lineIndex + 1 < bezier.elements.count) {
            indexes.insert(lineIndex + 1)
        }
        if (lineIndex + 2 <= max) || (lineIndex + 2 < bezier.elements.count) {
            indexes.insert(lineIndex + 2)
        }
    }

    /// Generates a new smooth Bézier curve element using the Antigrain algorithm.
    ///
    /// This method calculates the control points for a cubic Bézier curve segment
    /// that smoothly connects p1 to p2, taking into account the neighboring points p0 and p3.
    ///
    /// - Parameters:
    ///   - smoothFactor: The smoothness factor to apply.
    ///   - p0: The point before p1, used to influence the curve's entry direction (optional).
    ///   - p1: The starting point of this curve segment.
    ///   - p2: The ending point of this curve segment.
    ///   - p3: The point after p2, used to influence the curve's exit direction.
    /// - Returns: A `BezierElementStream.Element` representing the calculated smooth curve from p1 to p2.

    private static func newCurve(smoothFactor: CGFloat,
                                 p0: CGPoint? = nil,
                                 p1: CGPoint,
                                 p2: Polyline.Point,
                                 p3: CGPoint) -> BezierElementStream.Element {
        let p0 = p0 ?? p1

        let c1 = CGPoint(x: (p0.x + p1.x) / 2.0, y: (p0.y + p1.y) / 2.0)
        let c2 = CGPoint(x: (p1.x + p2.x) / 2.0, y: (p1.y + p2.y) / 2.0)
        let c3 = CGPoint(x: (p2.x + p3.x) / 2.0, y: (p2.y + p3.y) / 2.0)

        let len1 = sqrt((p1.x - p0.x) * (p1.x - p0.x) + (p1.y - p0.y) * (p1.y - p0.y))
        let len2 = sqrt((p2.x - p1.x) * (p2.x - p1.x) + (p2.y - p1.y) * (p2.y - p1.y))
        let len3 = sqrt((p3.x - p2.x) * (p3.x - p2.x) + (p3.y - p2.y) * (p3.y - p2.y))

        let k1 = len1 / (len1 + len2)
        let k2 = len2 / (len2 + len3)

        let m1 = CGPoint(x: c1.x + (c2.x - c1.x) * k1, y: c1.y + (c2.y - c1.y) * k1)
        let m2 = CGPoint(x: c2.x + (c3.x - c2.x) * k2, y: c2.y + (c3.y - c2.y) * k2)

        // Resulting control points. Here smooth_value is mentioned
        // above coefficient K whose value should be in range [0...1].
        var ctrl1 = CGPoint(x: m1.x + (c2.x - m1.x) * smoothFactor + p1.x - m1.x,
                              y: m1.y + (c2.y - m1.y) * smoothFactor + p1.y - m1.y)

        var ctrl2 = CGPoint(x: m2.x + (c2.x - m2.x) * smoothFactor + p2.x - m2.x,
                            y: m2.y + (c2.y - m2.y) * smoothFactor + p2.y - m2.y)

        if ctrl1.x.isNaN || ctrl1.y.isNaN {
            ctrl1 = p1
        }

        if ctrl2.x.isNaN || ctrl2.y.isNaN {
            ctrl2 = p2.location
        }

        return .curveTo(point: p2, ctrl1: ctrl1, ctrl2: ctrl2)
    }
}
