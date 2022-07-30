//
//  NaiveDouglasPeucker.swift
//  Inkable
//
//  Created by Adam Wulf on 8/18/20.
//

import Foundation
import CoreGraphics
import SwiftToolbox

/// Removes points from `strokes` according to the Ramer-Douglas-Peucker algorithm
/// https://en.wikipedia.org/wiki/Ramer%E2%80%93Douglas%E2%80%93Peucker_algorithm
open class NaiveDouglasPeucker: ProducerConsumer {

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
        var dmax: CGFloat = 0
        var index: Int = 0
        let lastItem: Int = points.count
        let line = Line(points[0], points[lastItem - 1])

        for i in 0..<lastItem {
            let d = perpendicularDistance(from: points[i], to: line)
            if d > dmax {
                index = i
                dmax = d
            }
        }

        // If max distance is greater than epsilon, recursively simplify
        if dmax > epsilon {
            // Recursive call
            let rangeA = points[0...index]
            let rangeB = points[index..<lastItem]
            let resultA = douglasPeucker(for: Array(points[rangeA.startIndex..<rangeA.endIndex]))
            let resultB = douglasPeucker(for: Array(points[rangeB.startIndex..<rangeB.endIndex]))

            // Build the result list
            return resultA[0..<resultA.count - 1] + resultB
        } else {
            return [points[0], points[lastItem - 1]]
        }
    }
}

extension NaiveDouglasPeucker {
    typealias Line = (start: Polyline.Point, end: Polyline.Point)

    func perpendicularDistance(from point: Polyline.Point, to line: Line) -> CGFloat {
        let max = hypot(line.end.y - line.start.y, line.end.x - line.start.x)
        return abs((line.end.y - line.start.y) * point.x - (line.end.x - line.start.x) * point.y + line.end.x * line.start.y - line.end.y * line.start.x) / max
    }
}
