//
//  BezierStream.swift
//  Inkable
//
//  Created by Adam Wulf on 3/14/21.
//

import Foundation
import UIKit
import PerformanceBezier
import SwiftToolbox

/// Transforms Polyline input into UIBezierPath output
open class BezierStream: ProducerConsumer {

    public struct Produces {
        public var paths: [UIBezierPath]
        public var deltas: [Delta]
        public init(paths: [UIBezierPath], deltas: [Delta]) {
            self.paths = paths
            self.deltas = deltas
        }

        public static var empty: Produces {
            return Produces(paths: [], deltas: [])
        }
    }

    public private(set) var paths: [UIBezierPath] = []
    private(set) var produced: Produces?
    public var isEnabled: Bool = true {
        didSet {
            replay()
        }
    }

    public typealias Consumes = PolylineStream.Produces

    public enum Delta: Equatable, CustomDebugStringConvertible {
        case addedBezierPath(index: Int)
        case updatedBezierPath(index: Int, updatedIndexes: MinMaxIndex)
        case completedBezierPath(index: Int)
        case unhandled(event: DrawEvent)

        public var debugDescription: String {
            switch self {
            case .addedBezierPath(let index):
                return "addedBezierPath(\(index))"
            case .updatedBezierPath(let index, let indexSet):
                return "updatedBezierPath(\(index), \(indexSet)"
            case .completedBezierPath(let index):
                return "completedBezierPath(\(index))"
            case .unhandled(let event):
                return "unhandledEvent(\(event.identifier))"
            }
        }
    }

    // MARK: - Private

    public private(set) var smoother: Smoother
    var consumers: [(process: (Produces) -> Void, reset: () -> Void)] = []
    private var builders: [BezierBuilder] = []
    /// Maps the index of a TouchPointCollection from our input to the index of the matching stroke in `strokes`
    private(set) var indexToIndex: [Int: Int] = [:]

    // MARK: - Init

    public init(smoother: Smoother) {
        self.smoother = smoother
    }

    // MARK: - Consumer<Polyline>

    public func reset() {
        waiting = []
        builders = []
        indexToIndex = [:]
        consumers.forEach({ $0.reset() })
    }

    // MARK: - BezierStreamProducer

    public func addConsumer<Customer>(_ consumer: Customer) where Customer: Consumer, Customer.Consumes == Produces {
        consumers.append((process: consumer.consume, reset: consumer.reset))
    }

    public func addConsumer(_ block: @escaping (Produces) -> Void, reset: @escaping () -> Void) {
        consumers.append((process: block, reset: reset))
    }

    // MARK: - ProducerConsumer<Polyline>

    @discardableResult
    public func produce(with input: Consumes) -> Produces {
        guard isEnabled else {
            waiting.append(input)
            return produced ?? Produces(paths: [], deltas: [])
        }
        var deltas: [Delta] = []

        for delta in input.deltas {
            switch delta {
            case .addedPolyline(let lineIndex):
                assert(indexToIndex[lineIndex] == nil, "Cannot add existing line")
                let line = input.lines[lineIndex]
                let builder = BezierBuilder(smoother: smoother)
                builder.update(with: line, at: MinMaxIndex(0 ..< line.points.count))
                let builderIndex = builders.count
                indexToIndex[lineIndex] = builderIndex
                builders.append(builder)
                deltas.append(.addedBezierPath(index: builderIndex))
            case .updatedPolyline(let lineIndex, let updatedIndexes):
                let line = input.lines[lineIndex]
                guard let builderIndex = indexToIndex[lineIndex] else { assertionFailure("path at \(lineIndex) does not exist"); continue }
                let builder = builders[builderIndex]
                let updateElementIndexes = builder.update(with: line, at: updatedIndexes)
                deltas.append(.updatedBezierPath(index: builderIndex, updatedIndexes: updateElementIndexes))
            case .completedPolyline(let lineIndex):
                guard let index = indexToIndex[lineIndex] else { assertionFailure("path at \(lineIndex) does not exist"); continue }
                deltas.append(.completedBezierPath(index: index))
            case .unhandled(let event):
                deltas.append(.unhandled(event: event))
            }
        }

        let output = BezierStream.Produces(paths: builders.map({ $0.path }), deltas: deltas)
        self.produced = output
        paths = output.paths
        consumers.forEach({ $0.process(output) })
        return output
    }

    private var waiting: [Consumes] = []
    private func replay() {
        guard isEnabled else { return }
        for input in waiting {
            consume(input)
        }
        waiting.removeAll()
    }

    private class BezierBuilder {
        private var elements: [BezierStream.Element] = []
        private let smoother: Smoother
        private(set) var path = UIBezierPath()

        init(smoother: Smoother) {
            self.smoother = smoother
        }

        @discardableResult
        func update(with line: Polyline, at lineIndexes: MinMaxIndex) -> MinMaxIndex {
            let updatedPathIndexes = smoother.elementIndexes(for: line, at: lineIndexes, with: path)
            guard
                let min = updatedPathIndexes.first,
                let max = updatedPathIndexes.last
            else {
                return updatedPathIndexes
            }
            let updatedPath: UIBezierPath
            if min - 1 < path.elementCount,
               min - 1 >= 0 {
                updatedPath = path.trimming(toElement: min - 1, andTValue: 1.0)
            } else {
                updatedPath = path.buildEmpty()
            }
            for elementIndex in min ... max {
                assert(elementIndex <= elements.count, "Invalid element index")
                if updatedPathIndexes.contains(elementIndex) {
                    if elementIndex > smoother.maxIndex(for: line) {
                        // skip this element, it was deleted
                    } else {
                        let element = smoother.element(for: line, at: elementIndex)
                        if elementIndex == elements.count {
                            elements.append(element)
                        } else {
                            elements[elementIndex] = element
                        }
                        updatedPath.append(element)
                    }
                } else {
                    // use the existing element
                    let element = elements[elementIndex]
                    updatedPath.append(element)
                }
            }
            for elementIndex in max + 1 ..< elements.count {
                let element = elements[elementIndex]
                updatedPath.append(element)
            }
            path = updatedPath
            return updatedPathIndexes
        }
    }
}

public extension BezierStream {
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

        public static func == (lhs: BezierStream.Element, rhs: BezierStream.Element) -> Bool {
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
    func append(_ element: BezierStream.Element) {
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
