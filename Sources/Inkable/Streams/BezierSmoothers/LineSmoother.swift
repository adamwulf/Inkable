//
//  LineSmoother.swift
//  Inkable
//
//  Created by Adam Wulf on 3/19/21.
//

import Foundation
import UIKit

/// A smoother that converts a `Polyline` into a series of straight line Bézier elements.
///
/// The `LineSmoother` is a simple implementation of the `Smoother` protocol that
/// creates a series of straight line Bézier elements from the points in a `Polyline`.
/// It does not perform any actual smoothing or curve fitting, but rather creates
/// a direct line-to-line representation of the input points.
///
/// Use this smoother when you want to preserve the exact shape of the input polyline
/// without any smoothing or curve fitting. It provides a one-to-one mapping between
/// input points and output line segments.
open class LineSmoother: Smoother {

    public init() {
        // noop
    }

    public func element(for line: Polyline, at elementIndex: Int) -> BezierElementStream.Element {
        assert(elementIndex >= 0 && elementIndex <= maxIndex(for: line))

        if elementIndex == 0 {
            return .moveTo(point: line.points[0])
        }

        return .lineTo(point: line.points[elementIndex])
    }

    public func maxIndex(for line: Polyline) -> Int {
        return line.points.count - 1
    }

    public func elementIndexes(for line: Polyline, at lineIndexes: MinMaxIndex, with bezier: BezierElementStream.Bezier) -> MinMaxIndex {
        return lineIndexes
    }

    public func elementIndexes(for line: Polyline, at lineIndex: Int, with bezier: BezierElementStream.Bezier) -> MinMaxIndex {
        assert(lineIndex >= 0 && (lineIndex < line.points.count || lineIndex < bezier.elements.count))
        return MinMaxIndex(lineIndex)
    }
}
