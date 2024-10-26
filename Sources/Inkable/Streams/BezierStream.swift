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
        public var elements: [[Element]]
        public var deltas: [Delta]
        public init(elements: [[Element]], deltas: [Delta]) {
            self.elements = elements
            self.deltas = deltas
        }
        
        public static var empty: Produces {
            return Produces(elements: [], deltas: [])
        }
    }
    
    public enum Element: Equatable, CustomDebugStringConvertible {
        case moveTo(point: Polyline.Point)
        case lineTo(point: Polyline.Point)
        case curveTo(point: Polyline.Point, ctrl1: CGPoint, ctrl2: CGPoint)
        
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
        case addedElements(index: Int)
        case updatedElements(index: Int, updatedIndexes: MinMaxIndex)
        case completedElements(index: Int)
        case unhandled(event: DrawEvent)
        
        public var debugDescription: String {
            switch self {
            case .addedElements(let index):
                return "addedElements(\(index))"
            case .updatedElements(let index, let indexSet):
                return "updatedElements(\(index), \(indexSet)"
            case .completedElements(let index):
                return "completedElements(\(index))"
            case .unhandled(let event):
                return "unhandledEvent(\(event.identifier))"
            }
        }
    }
    
    public private(set) var smoother: Smoother
    private var builders: [ElementBuilder] = []
    private var indexToIndex: [Int: Int] = [:]
    private var consumers: [(process: (Produces) -> Void, reset: () -> Void)] = []
    
    public init(smoother: Smoother) {
        self.smoother = smoother
    }
    
    public func reset() {
        builders = []
        indexToIndex = [:]
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
                deltas.append(.addedElements(index: builderIndex))
            case .updatedPolyline(let lineIndex, let updatedIndexes):
                let line = input.lines[lineIndex]
                guard let builderIndex = indexToIndex[lineIndex] else { assertionFailure("path at \(lineIndex) does not exist"); continue }
                let builder = builders[builderIndex]
                let updateElementIndexes = builder.update(with: line, at: updatedIndexes)
                deltas.append(.updatedElements(index: builderIndex, updatedIndexes: updateElementIndexes))
            case .completedPolyline(let lineIndex):
                guard let index = indexToIndex[lineIndex] else { assertionFailure("path at \(lineIndex) does not exist"); continue }
                deltas.append(.completedElements(index: index))
            case .unhandled(let event):
                deltas.append(.unhandled(event: event))
            }
        }
        
        let output = Produces(elements: builders.map({ $0.elements }), deltas: deltas)
        consumers.forEach({ $0.process(output) })
        return output
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
    
    public init() {}
    
    public func reset() {
        paths = []
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
        var deltas: [Delta] = []
        
        for delta in input.deltas {
            switch delta {
            case .addedElements(let index):
                let path = UIBezierPath()
                for element in input.elements[index] {
                    path.append(element)
                }
                paths.append(path)
                deltas.append(.addedBezierPath(index: index))
            case .updatedElements(let index, let updatedIndexes):
                let path = paths[index]
                path.removeAllPoints()
                for element in input.elements[index] {
                    path.append(element)
                }
                deltas.append(.updatedBezierPath(index: index, updatedIndexes: updatedIndexes))
            case .completedElements(let index):
                deltas.append(.completedBezierPath(index: index))
            case .unhandled(let event):
                deltas.append(.unhandled(event: event))
            }
        }
        
        let output = Produces(paths: paths, deltas: deltas)
        consumers.forEach({ $0.process(output) })
        return output
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
