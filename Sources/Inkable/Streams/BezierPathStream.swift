//
//  BezierPathStream.swift
//  Inkable
//
//  Created by Adam Wulf on 10/26/24.
//

import Foundation
import UIKit
import PerformanceBezier
import SwiftToolbox

// BezierPathStream: Transforms BezierElements into UIBezierPaths
open class BezierPathStream: ProducerConsumer {
    public typealias Consumes = BezierElementStream.Produces

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

    private var paths: [UIBezierPath] = []
    private var consumers: [(process: (Produces) -> Void, reset: () -> Void)] = []

    public var isEnabled: Bool = true {
        didSet {
            if isEnabled {
                replay()
            }
        }
    }
    private var waiting: [Consumes] = []

    public init() {}

    public func reset() {
        paths = []
        waiting = []
        consumers.forEach({ $0.reset() })
    }

    public func addConsumer<Customer>(_ consumer: Customer) where Customer: Consumer, Customer.Consumes == Produces {
        consumers.append((process: consumer.consume, reset: consumer.reset))
    }

    public func addConsumer(_ block: @escaping (Produces) -> Void, reset: @escaping () -> Void) {
        consumers.append((process: block, reset: reset))
    }

    @discardableResult
    public func produce(with input: Consumes) -> Produces {
        guard isEnabled else {
            waiting.append(input)
            return Produces.empty
        }

        var deltas: [Delta] = []

        for delta in input.deltas {
            switch delta {
            case .addedBezier(let index):
                let path = UIBezierPath()
                for element in input.beziers[index].elements {
                    path.append(element)
                }
                paths.append(path)
                deltas.append(.addedBezierPath(index: index))
            case .updatedBezier(let index, let updatedIndexes):
                let path = paths[index]
                path.removeAllPoints()
                for element in input.beziers[index].elements {
                    path.append(element)
                }
                deltas.append(.updatedBezierPath(index: index, updatedIndexes: updatedIndexes))
            case .completedBezier(let index):
                deltas.append(.completedBezierPath(index: index))
            case .unhandled(let event):
                deltas.append(.unhandled(event: event))
            }
        }

        let output = Produces(paths: paths, deltas: deltas)
        consumers.forEach({ $0.process(output) })
        return output
    }

    private func replay() {
        for input in waiting {
            _ = produce(with: input)
        }
        waiting.removeAll()
    }
}

extension UIBezierPath {
    func append(_ element: BezierElementStream.Element) {
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
