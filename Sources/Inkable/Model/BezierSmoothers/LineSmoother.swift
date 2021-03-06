//
//  LineSmoother.swift
//  Inkable
//
//  Created by Adam Wulf on 3/19/21.
//

import Foundation
import UIKit

open class LineSmoother: Smoother {

    public init() {
        // noop
    }

    public func element(for line: Polyline, at elementIndex: Int) -> BezierStream.Element {
        assert(elementIndex >= 0 && elementIndex <= maxIndex(for: line))

        if elementIndex == 0 {
            return .moveTo(point: line.points[0])
        }

        return .lineTo(point: line.points[elementIndex])
    }

    public func maxIndex(for line: Polyline) -> Int {
        return line.points.count - 1
    }

    public func elementIndexes(for line: Polyline, at lineIndexes: MinMaxIndex, with bezier: UIBezierPath) -> MinMaxIndex {
        return lineIndexes
    }

    public func elementIndexes(for line: Polyline, at lineIndex: Int, with bezier: UIBezierPath) -> MinMaxIndex {
        assert(lineIndex >= 0 && lineIndex < line.points.count)
        return MinMaxIndex(lineIndex)
    }
}
