//
//  IterativeDouglasPeucker.swift
//  Inkable
//
//  Created by Adam Wulf on 8/18/20.
//

import Foundation
import CoreGraphics
import SwiftToolbox

/// Naive implementation that removes recursion from the Douglas-Peucker algorithm
/// https://namekdev.net/2014/06/iterative-version-of-ramer-douglas-peucker-line-simplification-algorithm/
open class IterativeDouglasPeucker: ProducerConsumer {

    public typealias Consumes = PolylineStream.Produces
    public typealias Produces = PolylineStream.Produces

    // MARK: - Private

    private var consumers: [(process: (Produces) -> Void, reset: () -> Void)] = []

    // MARK: - Public

    public private(set) var lines: [Polyline] = []
    public var enabled: Bool = true
    public let epsilon: CGFloat

    // MARK: Init

    public init (epsilon: CGFloat = 2) {
        self.epsilon = epsilon
    }

    // MARK: - ProducerConsumer<Polyline>

    public func reset() {
        self.lines = []
        consumers.forEach({ $0.reset() })
    }

    // MARK: - Producer<Polyline>

    public func addConsumer<Customer>(_ consumer: Customer) where Customer: Consumer, Customer.Consumes == Produces {
        consumers.append((process: consumer.consume, reset: consumer.reset))
    }

    public func addConsumer(_ block: @escaping (Produces) -> Void) {
        consumers.append((process: block, reset: {}))
    }

    // MARK: - Consumer<Polyline>

    @discardableResult
    public func produce(with input: Consumes) -> Produces {
        guard enabled else {
            consumers.forEach({ $0.process(input) })
            return input
        }

        var output = Produces(lines: self.lines, deltas: [])

        let lineIndexes: [Int] = input.deltas.compactMap({
            switch $0 {
            case .addedPolyline(let index):
                assert(index == output.lines.count)
                output.lines.append(input.lines[index])
                return index
            case .updatedPolyline(let index, _):
                output.lines[index] = input.lines[index]
                return index
            case .completedPolyline(let index):
                output.lines[index] = input.lines[index]
                return index
            case .unhandled:
                return nil
            }
        }).unique()

        for index in lineIndexes {
            output.lines[index] = Polyline(points: douglasPeucker(for: output.lines[index].points))
        }

        output.deltas = input.deltas.map({ delta in
            switch delta {
            case .addedPolyline:
                return delta
            case .updatedPolyline(let index, _):
                let line = output.lines[index]
                let minMax = MinMaxIndex(0..<line.points.count)
                return .updatedPolyline(index: index, updatedIndexes: minMax)
            case .completedPolyline:
                return delta
            case .unhandled:
                return delta
            }
        }).unique()

        consumers.forEach({ $0.process(output) })
        self.lines = output.lines
        return output
    }

    func douglasPeucker(for points: [Polyline.Point]) -> [Polyline.Point] {
        guard points.count > 2 else { return points }

        var stack: [Range<Int>] = []
        stack.append(0..<points.count)

        var bitArray = Array(repeating: true, count: points.count)

        while let range = stack.pop() {
            guard range.count > 2 else { continue }
            let startIndex = range.startIndex
            let endIndex: Int = range.endIndex

            var dmax: CGFloat = 0
            var index: Int = startIndex
            let line = Line(points[startIndex], points[endIndex - 1])
            for i in startIndex + 1..<endIndex where bitArray[i] {
                let d = perpendicularDistance(from: points[i], to: line)
                if d > dmax {
                    index = i
                    dmax = d
                }
            }

            // If max distance is greater than epsilon, recursively simplify
            if dmax > epsilon {
                // Recursive call
                stack.append(startIndex..<index + 1)
                stack.append(index..<endIndex)
            } else {
                for i in startIndex + 1..<endIndex - 1 {
                    bitArray[i] = false
                }
            }
        }

        var points = points
        for i in bitArray.indices.reversed() where !bitArray[i] {
            points.remove(at: i)
        }

        return points
    }
}

extension IterativeDouglasPeucker {
    typealias Line = (start: Polyline.Point, end: Polyline.Point)

    func perpendicularDistance(from point: Polyline.Point, to line: Line) -> CGFloat {
        let max = hypot(line.end.y - line.start.y, line.end.x - line.start.x)
        return abs((line.end.y - line.start.y) * point.x - (line.end.x - line.start.x) * point.y + line.end.x * line.start.y - line.end.y * line.start.x) / max
    }
}
