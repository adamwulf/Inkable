//
//  Polyline.swift
//  Inkable
//
//  Created by Adam Wulf on 8/17/20.
//

import UIKit
import Foundation

public struct Polyline {

    // MARK: - Public Properties
    public internal(set) var isComplete: Bool
    public let touchIdentifier: String
    public var points: [Point]
    public var bounds: CGRect {
        return points.reduce(.null) { partialResult, point -> CGRect in
            return CGRect(x: min(partialResult.origin.x, point.x),
                          y: min(partialResult.origin.y, point.y),
                          width: max(partialResult.origin.x, point.x),
                          height: max(partialResult.origin.y, point.y))
        }
    }
    public init(touchPath: TouchPath) {
        isComplete = touchPath.isComplete
        touchIdentifier = touchPath.touchIdentifier
        points = touchPath.points.map({ Point(touchPoint: $0) })
    }

    public init(points: [Point]) {
        assert(!points.isEmpty)
        self.isComplete = true
        self.touchIdentifier = points.first!.event.touchIdentifier
        self.points = points
    }

    mutating func update(with path: TouchPath, indexSet: MinMaxIndex) -> MinMaxIndex {
        var indexesToRemove = MinMaxIndex()
        for index in indexSet {
            if index < path.points.count {
                if index < points.count {
                    points[index].location = path.points[index].event.location
                    points[index].force = path.points[index].event.force
                    points[index].azimuth = path.points[index].event.azimuth
                    points[index].altitudeAngle = path.points[index].event.altitudeAngle
                } else if index == points.count {
                    points.append(Point(touchPoint: path.points[index]))
                } else {
                    assertionFailure("Attempting to modify a point that doesn't yet exist. maybe an update is out of order?")
                }
            } else {
                indexesToRemove.insert(index)
            }
        }

        // Remove points from the end of the list toward the beginning
        for index in indexesToRemove.reversed() {
            guard index < points.count else {
                print("Error: unknown polyline index \(index)")
//                assertionFailure("Error: unknown polyline index \(index)")
                continue
            }
            points.remove(at: index)
        }

        isComplete = path.isComplete

        return indexSet
    }
}

extension Polyline: Equatable {
    public static func == (lhs: Polyline, rhs: Polyline) -> Bool {
        return lhs.points.count == rhs.points.count &&
        lhs.isComplete == rhs.isComplete &&
        lhs.touchIdentifier == rhs.touchIdentifier &&
        lhs.bounds == rhs.bounds &&
        lhs.points == rhs.points
    }
}

extension Polyline {
    /// A mutable version of `TouchPoint` that maintains a reference to the immutable point it's initialized from
    public struct Point: Equatable {

        // MARK: - Mutable
        public var force: CGFloat
        public var location: CGPoint
        public var altitudeAngle: CGFloat
        public var azimuth: CGFloat

        public var x: CGFloat {
            get {
                location.x
            }
            set {
                location.x = newValue
            }
        }

        public var y: CGFloat {
            get {
                location.y
            }
            set {
                location.y = newValue
            }
        }

        // MARK: - Immutable
        public let touchPoint: TouchPath.Point

        // MARK: - Immutable Computed
        public var event: TouchEvent {
            return touchPoint.event
        }
        public var expectsUpdate: Bool {
            return touchPoint.expectsUpdate
        }

        public init(touchPoint: TouchPath.Point) {
            self.force = touchPoint.event.force
            self.location = touchPoint.event.location
            self.altitudeAngle = touchPoint.event.altitudeAngle
            self.azimuth = touchPoint.event.azimuth

            self.touchPoint = touchPoint
        }
    }
}
