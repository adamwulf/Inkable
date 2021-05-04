//
//  NaiveDouglasPeucker.swift
//  Inkable
//
//  Created by Adam Wulf on 8/18/20.
//

import Foundation

/// Removes points from `strokes` according to the Ramer-Douglas-Peucker algorithm
/// https://en.wikipedia.org/wiki/Ramer%E2%80%93Douglas%E2%80%93Peucker_algorithm
public class NaiveDouglasPeucker: ProducerConsumer {

    public typealias Consumes = PolylineStream.Produces
    public typealias Produces = PolylineStream.Produces

    // MARK: - Private

    private var consumers: [(process: (Produces) -> Void, reset: () -> Void)] = []

    // MARK: - Public

    public var enabled: Bool = true

    // MARK: Init

    public init () {
    }

    // MARK: - ProducerConsumer<Polyline>

    public func reset() {
        consumers.forEach({ $0.reset() })
    }

    // MARK: - Producer<Polyline>

    public func addConsumer<Customer>(_ consumer: Customer) where Customer: Consumer, Customer.Consumes == Produces {
        consumers.append((process: { (produces: Produces) in
            consumer.consume(produces)
        }, reset: consumer.reset))
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

        // TODO: implement Douglas-Peucker algorithm to reduce the number of points
        consumers.forEach({ $0.process(input) })
        return input
    }
}
