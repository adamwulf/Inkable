//
//  ProducerConsumer.swift
//  Inkable
//
//  Created by Adam Wulf on 3/15/21.
//

import Foundation

public protocol Consumer {
    associatedtype Consumes
    func consume(_ input: Consumes)
    func reset()
}

public protocol Producer {
    associatedtype Produces

    func addConsumer<Customer>(_ consumer: Customer) where Customer: Consumer, Customer.Consumes == Produces
    func addConsumer(_ block: @escaping (Produces) -> Void)
    func reset()
}

public protocol ProducerConsumer: Producer, Consumer {
    @discardableResult
    func produce(with input: Consumes) -> Produces
}

extension ProducerConsumer {
    public func consume(_ input: Consumes) {
        produce(with: input)
    }

    @discardableResult
    public func nextStep<Customer>(_ consumer: Customer) -> Customer where Customer: Consumer, Customer.Consumes == Produces {
        addConsumer(consumer)
        return consumer
    }

    public func nextStep(_ block: @escaping (Produces) -> Void) {
        addConsumer(block)
    }
}

class ExampleStream: Producer {
    // How do I keep Customer generic here?
    typealias Produces = [TouchEvent]

    var consumerResets: [() -> Void] = []
    var consumers: [(Produces) -> Void] = []

    // Alternate idea to wrap them in an object instead of a loose closure
    struct AnyConsumer {
        let process: (Produces) -> Void
    }
    var wrappedCustomers: [AnyConsumer] = []

    func addConsumer<Customer>(_ consumer: Customer) where Customer: Consumer, Customer.Consumes == Produces {
        wrappedCustomers.append(AnyConsumer(process: consumer.consume))
        consumers.append({ (produces: Produces) in
            consumer.consume(produces)
        })
        consumerResets.append(consumer.reset)
    }
    func addConsumer(_ block: @escaping ([TouchEvent]) -> Void) {
        wrappedCustomers.append(AnyConsumer(process: block))
        consumers.append(block)
    }
    func reset() {
        consumerResets.forEach({ $0() })
    }
}

struct ExampleAnonymousConsumer: Consumer {
    typealias Consumes = [TouchEvent]

    var block: ([TouchEvent]) -> Void
    func consume(_ input: [TouchEvent]) {
        block(input)
    }
    func reset() {
        // noop
    }
}
