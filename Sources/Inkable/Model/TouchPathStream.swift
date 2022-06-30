//
//  TouchPathStream.swift
//  Inkable
//
//  Created by Adam Wulf on 8/16/20.
//

import UIKit

/// Input: An array of touch events from one or more touches representing one or more collections.
/// A `TouchPathStream` represents all of the different `TouchPathStream.Point` that share the same `touchIdentifier`
/// Output: A OrderedTouchPoints for each stroke of touch event data, which coalesces the events into current point data for that stroke
open class TouchPathStream: ProducerConsumer {

    public struct Produces {
        public var paths: [TouchPath]
        public var deltas: [Delta]
        public init(paths: [TouchPath], deltas: [Delta]) {
            self.paths = paths
            self.deltas = deltas
        }
    }
    public typealias Consumes = TouchEventStream.Produces

    public enum Delta: Equatable, CustomDebugStringConvertible {
        case addedTouchPath(index: Int)
        case updatedTouchPath(index: Int, updatedIndexes: IndexSet)
        case completedTouchPath(index: Int)
        case unhandled(event: DrawEvent)

        public var debugDescription: String {
            switch self {
            case .addedTouchPath(let index):
                return "addedTouchPath(\(index))"
            case .updatedTouchPath(let index, let indexSet):
                return "updatedTouchPath(\(index), \(indexSet)"
            case .completedTouchPath(let index):
                return "completedTouchPath(\(index))"
            case .unhandled(let event):
                return "unhandledEvent(\(event.identifier))"
            }
        }
    }

    // MARK: - Private

    private var touchToIndex: [UITouchIdentifier: Int]

    // MARK: - Public

    public private(set) var paths: [TouchPath]

    // MARK: - Init

    public init() {
        touchToIndex = [:]
        paths = []
    }

    // MARK: - ProducerConsumer<TouchPath>

    public func reset() {
        touchToIndex = [:]
        paths = []
        consumers.forEach({ $0.reset() })
    }

    // MARK: - Producer<TouchPath>

    private var consumers: [(process: (Produces) -> Void, reset: () -> Void)] = []

    public func addConsumer<Customer>(_ consumer: Customer) where Customer: Consumer, Customer.Consumes == Produces {
        consumers.append((process: { (produces: Produces) in
            consumer.consume(produces)
        }, reset: consumer.reset))
    }

    public func addConsumer(_ block: @escaping (Produces) -> Void) {
        consumers.append((process: block, reset: {}))
    }

    // MARK: - Consumer<TouchEvent>

    public func consume(_ input: [DrawEvent]) {
        produce(with: input)
    }

    @discardableResult
    public func produce(with input: Consumes) -> Produces {
        var deltas: [Delta] = []
        var processedTouchIdentifiers: [UITouchIdentifier] = []
        let updatedEventsPerTouch = input.reduce([:], { (result, event) -> [String: [TouchEvent]] in
            guard let event = event as? TouchEvent else { return result }

            var result = result
            if result[event.touchIdentifier] != nil {
                result[event.touchIdentifier]?.append(event)
            } else {
                result[event.touchIdentifier] = [event]
            }
            return result
        })

        for eventToProcess in input {
            guard let touchToProcess = eventToProcess as? TouchEvent else {
                deltas.append(.unhandled(event: eventToProcess))
                continue
            }
            // The event is a TouchEvent, so process it into its touch
            let touchIdentifier = touchToProcess.touchIdentifier
            guard
                !processedTouchIdentifiers.contains(touchIdentifier),
                let events = updatedEventsPerTouch[touchIdentifier]
            else
            {
                // we've already processed all of the events for this touch,
                // so move onto the next event
                continue
            }

            processedTouchIdentifiers.append(touchIdentifier)
            if let index = touchToIndex[touchIdentifier] {
                let path = paths[index]
                let updatedIndexes = path.add(touchEvents: events)
                deltas.append(.updatedTouchPath(index: index, updatedIndexes: updatedIndexes))

                if path.isComplete {
                    deltas.append(.completedTouchPath(index: index))
                }
            } else if let touchIdentifier = events.first?.touchIdentifier,
                      let path = TouchPath(touchEvents: events) {
                let index = paths.count
                touchToIndex[touchIdentifier] = index
                paths.append(path)
                deltas.append(.addedTouchPath(index: index))

                if path.isComplete {
                    deltas.append(.completedTouchPath(index: index))
                }
            }
        }

        let output = Produces(paths: paths, deltas: deltas)
        consumers.forEach({ $0.process(output) })
        return output
    }
}
