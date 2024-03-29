//
//  NaivePointDistance.swift
//  Inkable
//
//  Created by Adam Wulf on 8/18/20.
//

import Foundation

/// Removes points from `strokes` that are within a minimum distance of each other
open class NaivePointDistance: ProducerConsumer {

    public typealias Consumes = PolylineStream.Produces
    public typealias Produces = PolylineStream.Produces

    // MARK: - Private

    private var consumers: [(process: (Produces) -> Void, reset: () -> Void)] = []

    // MARK: - Public

    public var isEnabled: Bool = true

    // MARK: Init

    public init () {
    }

    // MARK: - ProducerConsumer<Polyline>

    public func reset() {
        consumers.forEach({ $0.reset() })
    }

    // MARK: - Producer<Polyline>

    public func addConsumer<Customer>(_ consumer: Customer) where Customer: Consumer, Customer.Consumes == Produces {
        consumers.append((process: consumer.consume, reset: consumer.reset))
    }

    public func addConsumer(_ block: @escaping (Produces) -> Void, reset: @escaping () -> Void) {
        consumers.append((process: block, reset: reset))
    }

    // MARK: - Consumer<Polyline>

    @discardableResult
    public func produce(with input: Consumes) -> Produces {
        guard isEnabled else {
            consumers.forEach({ $0.process(input) })
            return input
        }

        // Future: implement filtering a stroke's points by their distance

        consumers.forEach({ $0.process(input) })
        return input
    }
}
