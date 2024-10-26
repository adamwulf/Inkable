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

// BezierElementStream: Transforms Polyline input into BezierElements
open class BezierElementStream: ProducerConsumer {
    public typealias Consumes = PolylineStream.Produces
    
    public struct Produces {
        public var beziers: [Bezier]
        public var deltas: [Delta]
        init(beziers: [Bezier], deltas: [Delta]) {
            self.beziers = beziers
            self.deltas = deltas
        }
        
        public static var empty: Produces {
            return Produces(beziers: [], deltas: [])
        }
    }
    
    public struct Bezier: Equatable {
        public var elements: [Element]
        
        init(elements: [Element]) {
            self.elements = elements
        }
    }
    
    public enum Element: Equatable, CustomDebugStringConvertible {
        case moveTo(point: Polyline.Point)
        case lineTo(point: Polyline.Point)
        case curveTo(point: Polyline.Point, ctrl1: CGPoint, ctrl2: CGPoint)

        var endPoint: Polyline.Point {
            switch self {
            case .moveTo(let point): return point
            case .lineTo(let point): return point
            case .curveTo(let point, _, _): return point
            }
        }

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
    }
    
    public enum Delta: Equatable, CustomDebugStringConvertible {
        case addedBezier(index: Int)
        case updatedBezier(index: Int, updatedIndexes: MinMaxIndex)
        case completedBezier(index: Int)
        case unhandled(event: DrawEvent)
        
        public var debugDescription: String {
            switch self {
            case .addedBezier(let index):
                return "addedBezier(\(index))"
            case .updatedBezier(let index, let indexSet):
                return "updatedBezier(\(index), \(indexSet)"
            case .completedBezier(let index):
                return "completedBezier(\(index))"
            case .unhandled(let event):
                return "unhandledEvent(\(event.identifier))"
            }
        }
    }

    var produced: Produces?
    public private(set) var smoother: Smoother
    private var builders: [ElementBuilder] = []
    private var indexToIndex: [Int: Int] = [:]
    private var consumers: [(process: (Produces) -> Void, reset: () -> Void)] = []
    
    public var isEnabled: Bool = true {
        didSet {
            if isEnabled {
                replay()
            }
        }
    }
    private var waiting: [Consumes] = []

    var beziers: [Bezier] {
        return builders.map({ Bezier(elements: $0.elements) })
    }

    public init(smoother: Smoother) {
        self.smoother = smoother
    }
    
    public func reset() {
        builders = []
        indexToIndex = [:]
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
            case .addedPolyline(let lineIndex):
                assert(indexToIndex[lineIndex] == nil, "Cannot add existing line")
                let line = input.lines[lineIndex]
                let builder = ElementBuilder(smoother: smoother)
                builder.update(with: line, at: MinMaxIndex(0 ..< line.points.count))
                let builderIndex = builders.count
                indexToIndex[lineIndex] = builderIndex
                builders.append(builder)
                deltas.append(.addedBezier(index: builderIndex))
            case .updatedPolyline(let lineIndex, let updatedIndexes):
                let line = input.lines[lineIndex]
                guard let builderIndex = indexToIndex[lineIndex] else { assertionFailure("path at \(lineIndex) does not exist"); continue }
                let builder = builders[builderIndex]
                let updateElementIndexes = builder.update(with: line, at: updatedIndexes)
                deltas.append(.updatedBezier(index: builderIndex, updatedIndexes: updateElementIndexes))
            case .completedPolyline(let lineIndex):
                guard let index = indexToIndex[lineIndex] else { assertionFailure("path at \(lineIndex) does not exist"); continue }
                deltas.append(.completedBezier(index: index))
            case .unhandled(let event):
                deltas.append(.unhandled(event: event))
            }
        }
        
        let output = Produces(beziers: builders.map({ Bezier(elements: $0.elements) }), deltas: deltas)
        consumers.forEach({ $0.process(output) })
        produced = output
        return output
    }
    
    private func replay() {
        for input in waiting {
            _ = produce(with: input)
        }
        waiting.removeAll()
    }
    
    private class ElementBuilder {
        private(set) var elements: [Element] = []
        private let smoother: Smoother
        
        init(smoother: Smoother) {
            self.smoother = smoother
        }
        
        @discardableResult
        func update(with line: Polyline, at lineIndexes: MinMaxIndex) -> MinMaxIndex {
            let updatedElementIndexes = smoother.elementIndexes(for: line, at: lineIndexes, with: UIBezierPath())
            guard
                let min = updatedElementIndexes.first,
                let max = updatedElementIndexes.last
            else {
                return updatedElementIndexes
            }
            
            for elementIndex in min ... max {
                if updatedElementIndexes.contains(elementIndex) {
                    if elementIndex > smoother.maxIndex(for: line) {
                        // skip this element, it was deleted
                    } else {
                        let element = smoother.element(for: line, at: elementIndex)
                        if elementIndex == elements.count {
                            elements.append(element)
                        } else {
                            elements[elementIndex] = element
                        }
                    }
                }
            }
            
            return updatedElementIndexes
        }
    }
}
