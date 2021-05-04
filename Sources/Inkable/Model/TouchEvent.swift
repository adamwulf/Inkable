//
//  TouchEvent.swift
//  Inkable
//
//  Created by Adam Wulf on 8/10/20.
//

import UIKit

public typealias TouchEventIdentifier = String
public typealias PointIdentifier = String
public typealias EstimationUpdateIndex = NSNumber

// Probably need to do something like this linked issue when encoding/decoding
// https://stackoverflow.com/questions/59364986/swift-decode-encode-an-array-of-generics-with-different-types
public class DrawEvent: Codable {
    public typealias Identifier = String

    enum CodingKeys: CodingKey {
        case identifier
    }

    /// A completely unique identifier per event, even for events built from
    /// the same touch or coalescedTouch
    public let identifier: Identifier

    public init(identifier: Identifier) {
        self.identifier = identifier
    }

    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.identifier = try values.decode(Identifier.self, forKey: .identifier)
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(identifier, forKey: .identifier)
    }
}

public class TouchEvent: DrawEvent {

    /// An identifier unique to the touch that created this event. Events with the same
    /// touch will also have the same touchIdentifier
    public let touchIdentifier: UITouchIdentifier
    public var pointIdentifier: PointIdentifier {
        if let estimationUpdateIndex = estimationUpdateIndex {
            return touchIdentifier + ":\(estimationUpdateIndex)"
        } else {
            return touchIdentifier + ":" + identifier
        }
    }
    public let timestamp: TimeInterval
    public let type: UITouch.TouchType
    public let phase: UITouch.Phase
    public let force: CGFloat
    public let maximumPossibleForce: CGFloat
    public let altitudeAngle: CGFloat
    public let azimuthUnitVector: CGVector
    public let azimuth: CGFloat
    public let majorRadius: CGFloat
    public let majorRadiusTolerance: CGFloat
    public let location: CGPoint
    public let estimationUpdateIndex: EstimationUpdateIndex?
    public let estimatedProperties: UITouch.Properties
    public let estimatedPropertiesExpectingUpdates: UITouch.Properties
    public let isUpdate: Bool
    public let isPrediction: Bool

    // MARK: - Non-coded properties

    public let view: UIView?

    // MARK: - Computed Properties

    public var expectsLocationUpdate: Bool {
        return estimatedPropertiesExpectingUpdates.contains(UITouch.Properties.location)
    }

    public var expectsForceUpdate: Bool {
        return estimatedPropertiesExpectingUpdates.contains(UITouch.Properties.force)
    }

    public var expectsAzimuthUpdate: Bool {
        return estimatedPropertiesExpectingUpdates.contains(UITouch.Properties.azimuth)
    }

    public var expectsUpdate: Bool {
        return expectsForceUpdate || expectsAzimuthUpdate || expectsLocationUpdate
    }

    public convenience init(coalescedTouch: UITouch, touch: UITouch, in view: UIView, isUpdate: Bool, isPrediction: Bool) {
        self.init(identifier: UUID.init().uuidString,
                  touchIdentifier: touch.identifer,
                  timestamp: coalescedTouch.timestamp,
                  type: coalescedTouch.type,
                  phase: coalescedTouch.phase,
                  force: coalescedTouch.force,
                  maximumPossibleForce: coalescedTouch.maximumPossibleForce,
                  altitudeAngle: coalescedTouch.altitudeAngle,
                  azimuthUnitVector: coalescedTouch.azimuthUnitVector(in: view),
                  azimuth: coalescedTouch.azimuthAngle(in: view),
                  majorRadius: coalescedTouch.majorRadius,
                  majorRadiusTolerance: coalescedTouch.majorRadiusTolerance,
                  location: coalescedTouch.location(in: view),
                  estimationUpdateIndex: coalescedTouch.estimationUpdateIndex,
                  estimatedProperties: coalescedTouch.estimatedProperties,
                  estimatedPropertiesExpectingUpdates: coalescedTouch.estimatedPropertiesExpectingUpdates,
                  isUpdate: isUpdate,
                  isPrediction: isPrediction,
                  in: view)
    }

    public init(identifier: TouchEventIdentifier,
                touchIdentifier: UITouchIdentifier,
                timestamp: TimeInterval,
                type: UITouch.TouchType,
                phase: UITouch.Phase,
                force: CGFloat,
                maximumPossibleForce: CGFloat,
                altitudeAngle: CGFloat,
                azimuthUnitVector: CGVector,
                azimuth: CGFloat,
                majorRadius: CGFloat,
                majorRadiusTolerance: CGFloat,
                location: CGPoint,
                estimationUpdateIndex: EstimationUpdateIndex?,
                estimatedProperties: UITouch.Properties,
                estimatedPropertiesExpectingUpdates: UITouch.Properties,
                isUpdate: Bool,
                isPrediction: Bool,
                in view: UIView?) {
        self.touchIdentifier = touchIdentifier
        self.timestamp = timestamp
        self.type = type
        self.phase = phase
        self.force = force
        self.maximumPossibleForce = maximumPossibleForce
        self.altitudeAngle = altitudeAngle
        self.azimuthUnitVector = azimuthUnitVector
        self.azimuth = azimuth
        self.majorRadius = majorRadius
        self.majorRadiusTolerance = majorRadiusTolerance
        self.location = location
        self.estimationUpdateIndex = estimationUpdateIndex
        self.estimatedProperties = estimatedProperties
        self.estimatedPropertiesExpectingUpdates = estimatedPropertiesExpectingUpdates
        self.isUpdate = isUpdate
        self.isPrediction = isPrediction
        self.view = view
        super.init(identifier: identifier)
    }

    public convenience init(touchIdentifier: UITouchIdentifier,
                            type: UITouch.TouchType = .direct,
                            phase: UITouch.Phase,
                            force: CGFloat = 1,
                            location: CGPoint,
                            estimationUpdateIndex: EstimationUpdateIndex? = nil,
                            estimatedProperties: UITouch.Properties,
                            estimatedPropertiesExpectingUpdates: UITouch.Properties,
                            isUpdate: Bool,
                            isPrediction: Bool) {
        self.init(identifier: UUID().uuidString,
                  touchIdentifier: touchIdentifier,
                  timestamp: Date().timeIntervalSinceReferenceDate,
                  type: type,
                  phase: phase,
                  force: force,
                  maximumPossibleForce: 1,
                  altitudeAngle: 0,
                  azimuthUnitVector: CGVector.zero,
                  azimuth: 0,
                  majorRadius: 1,
                  majorRadiusTolerance: 1,
                  location: location,
                  estimationUpdateIndex: estimationUpdateIndex,
                  estimatedProperties: estimatedProperties,
                  estimatedPropertiesExpectingUpdates: estimatedPropertiesExpectingUpdates,
                  isUpdate: isUpdate,
                  isPrediction: isPrediction,
                  in: nil)
    }

    public func isSameTouchAs(event: TouchEvent) -> Bool {
        return touchIdentifier == event.touchIdentifier
    }

    // MARK: - Codable

    enum CodingKeys: CodingKey {
        case touchIdentifier
        case timestamp
        case type
        case phase
        case force
        case maximumPossibleForce
        case altitudeAngle
        case azimuthUnitVector
        case azimuth
        case majorRadius
        case majorRadiusTolerance
        case location
        case estimationUpdateIndex
        case estimatedProperties
        case estimatedPropertiesExpectingUpdates
        case isUpdate
        case isPrediction
    }

    required public init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.touchIdentifier = try values.decode(UITouchIdentifier.self, forKey: .touchIdentifier)
        self.timestamp = try values.decode(TimeInterval.self, forKey: .timestamp)
        self.type = try values.decode(UITouch.TouchType.self, forKey: .type)
        self.phase = try values.decode(UITouch.Phase.self, forKey: .phase)
        self.force = try values.decode(CGFloat.self, forKey: .force)
        self.maximumPossibleForce = try values.decode(CGFloat.self, forKey: .maximumPossibleForce)
        self.altitudeAngle = try values.decode(CGFloat.self, forKey: .altitudeAngle)
        self.azimuthUnitVector = try values.decode(CGVector.self, forKey: .azimuthUnitVector)
        self.azimuth = try values.decode(CGFloat.self, forKey: .azimuth)
        self.majorRadius = try values.decode(CGFloat.self, forKey: .majorRadius)
        self.majorRadiusTolerance = try values.decode(CGFloat.self, forKey: .majorRadiusTolerance)
        self.location = try values.decode(CGPoint.self, forKey: .location)

        if let index = try values.decodeIfPresent(Double.self, forKey: .estimationUpdateIndex) {
            self.estimationUpdateIndex = NSNumber(value: index)
        } else {
            self.estimationUpdateIndex = nil
        }

        self.estimatedProperties = try values.decode(UITouch.Properties.self, forKey: .estimatedProperties)
        self.estimatedPropertiesExpectingUpdates = try values.decode(UITouch.Properties.self, forKey: .estimatedPropertiesExpectingUpdates)
        self.isUpdate = try values.decode(Bool.self, forKey: .isUpdate)
        self.isPrediction = try values.decode(Bool.self, forKey: .isPrediction)
        self.view = nil
        try super.init(from: decoder)
    }

    override public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try super.encode(to: encoder)
        try container.encode(touchIdentifier, forKey: .touchIdentifier)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(type, forKey: .type)
        try container.encode(phase, forKey: .phase)
        try container.encode(force, forKey: .force)
        try container.encode(maximumPossibleForce, forKey: .maximumPossibleForce)
        try container.encode(altitudeAngle, forKey: .altitudeAngle)
        try container.encode(azimuthUnitVector, forKey: .azimuthUnitVector)
        try container.encode(azimuth, forKey: .azimuth)
        try container.encode(majorRadius, forKey: .majorRadius)
        try container.encode(majorRadiusTolerance, forKey: .majorRadiusTolerance)
        try container.encode(location, forKey: .location)
        try container.encodeIfPresent(estimationUpdateIndex?.doubleValue, forKey: .estimationUpdateIndex)
        try container.encode(estimatedProperties, forKey: .estimatedProperties)
        try container.encode(estimatedPropertiesExpectingUpdates, forKey: .estimatedPropertiesExpectingUpdates)
        try container.encode(isUpdate, forKey: .isUpdate)
        try container.encode(isPrediction, forKey: .isPrediction)
    }
}

extension DrawEvent: Hashable {
    public static func == (lhs: DrawEvent, rhs: DrawEvent) -> Bool {
        return lhs.identifier == rhs.identifier
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}
