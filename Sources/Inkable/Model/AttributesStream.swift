//
//  AttributesStream.swift
//  Inkable
//
//  Created by Adam Wulf on 3/19/21.
//

import Foundation
import UIKit

open class ToolEvent: DrawEvent {
    public var style: AttributesStream.ToolStyle

    public init(style: AttributesStream.ToolStyle) {
        self.style = style
        super.init(identifier: UUID().uuidString)
    }

    // MARK: - Codable

    enum CodingKeys: CodingKey {
        case width
        case color
    }

    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let width = try values.decode(CGFloat.self, forKey: .width)
        let color = try? values.decode(CodableColor.self, forKey: .color).color
        style = AttributesStream.ToolStyle(width: width, color: color)
        try super.init(from: decoder)
    }
    override public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try super.encode(to: encoder)
        try container.encode(style.width, forKey: .width)
        try container.encode(style.color?.codable(), forKey: .color)
    }
}

open class AttributesStream: ProducerConsumer {

    public typealias Produces = BezierStream.Produces
    public typealias Consumes = BezierStream.Produces

    enum CodingKeys: CodingKey {
        case width
        case color
    }

    public struct ToolStyle {
        public let width: CGFloat
        public let color: UIColor?
        public init(width: CGFloat, color: UIColor?) {
            self.width = width
            self.color = color
        }
    }

    // MARK: - Private

    /// Maps the index of a TouchPointCollection from our input to the index of the matching stroke in `strokes`
    private(set) var indexToIndex: [Int: Int] = [:]

    // MARK: - Public

    var consumers: [(process: (Produces) -> Void, reset: () -> Void)] = []
    private(set) public var style: ToolStyle
    /// The most recent output that was produced
    public private(set) var produced: Produces?

    public var styleOverride: ((_ delta: BezierStream.Delta) -> ToolStyle?)?

    // MARK: - Init

    public init() {
        style = ToolStyle(width: 1.5, color: .black)
    }

    // MARK: - Consumer<Polyline>

    public func reset() {
        indexToIndex = [:]
        consumers.forEach({ $0.reset() })
    }

    // MARK: - BezierStreamProducer

    public func addConsumer<Customer>(_ consumer: Customer) where Customer: Consumer, Customer.Consumes == Produces {
        consumers.append((process: { (produces: Produces) in
            consumer.consume(produces)
        }, reset: consumer.reset))
    }

    public func addConsumer(_ block: @escaping (Produces) -> Void) {
        consumers.append((process: block, reset: {}))
    }

    // MARK: - ProducerConsumer<Polyline>

    @discardableResult
    public func produce(with input: Consumes) -> Produces {
        var output = Produces(paths: input.paths, deltas: [])
        for delta in input.deltas {
            let override = styleOverride?(delta)

            switch delta {
            case .addedBezierPath(let index):
                let style = override ?? self.style
                let path = input.paths[index]
                path.lineCapStyle = .round
                path.lineJoinStyle = .round
                path.color = style.color
                path.lineWidth = style.width
                output.deltas += [delta]
            case .unhandled(let event):
                if let event = event as? ToolEvent {
                    // update our style and consume the event
                    style = override ?? event.style
                } else {
                    output.deltas += [delta]
                }
            default:
                output.deltas += [delta]
            }
        }

        produced = output
        consumers.forEach({ $0.process(output) })
        return output
    }
}

public extension UIBezierPath {
    var color: UIColor? {
        get {
            let info = userInfo()
            guard let ret = info.object(forKey: "color") else { return nil }
            return ret as? UIColor
        }
        set {
            if let color = newValue {
                userInfo().setObject(color, forKey: "color" as NSString)
            } else {
                userInfo().removeObject(forKey: "color")
            }
        }
    }
}
