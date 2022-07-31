//
//  TouchPath.swift
//  Inkable
//
//  Created by Adam Wulf on 8/16/20.
//

import Foundation
import CoreGraphics

/// Input: a stream of touch events that match our `touchIdentifier`
/// Output: coalesce all of the touch events into defined points along the stroke
///
/// The touch events may come in any order, and many events may represent the same
/// touch location, ie, a predicted touch has been updated to a final location, even though
/// other events have been added since then.
///
/// This will take a strea of events: [a1, a2, b1, a3, b2, c1] and will coalesce events for
/// the same point, so that it can output a series of points [A, B, C]
///
/// The output points also know if they are predicted, expecting updates, or is finished
open class TouchPath {

    // MARK: - Public Properties
    public private(set) var touchIdentifier: String

    private var _points: [Point]?
    public var points: [Point] {
        if let _points = _points {
            return _points
        }
        let ret = confirmedPoints + predictedPoints
        _points = ret
        return ret
    }
    public var bounds: CGRect {
        return points.reduce(.null) { partialResult, point -> CGRect in
            return CGRect(x: min(partialResult.origin.x, point.event.location.x),
                          y: min(partialResult.origin.y, point.event.location.y),
                          width: max(partialResult.origin.x, point.event.location.x),
                          height: max(partialResult.origin.y, point.event.location.y))
        }
    }
    public var isComplete: Bool {
        // completed paths are allowed to have expectingUpdate
        let phase = confirmedPoints.last?.event.phase
        return (phase == .ended || phase == .cancelled) && predictedPoints.isEmpty
    }

    // MARK: - Private Properties
    /// Confirmed points have at least one non-predictive point
    private var confirmedPoints: [Point] {
        didSet {
            _points = nil
        }
    }
    /// Predicted points have only a single prediction event, and have been predicted in our most recent `process()` round
    private var predictedPoints: [Point] {
        didSet {
            _points = nil
        }
    }
    /// Consumable points are previously predicted points that were not used up by the previous `process()` when creating confirmed points.
    /// these should be used before any newly predicted points
    private var consumable: [Point]
    private var expectingUpdate: Set<String>
    private var eventToPoint: [PointIdentifier: Point]
    private var eventToIndex: [PointIdentifier: Int]

    // MARK: - Init
    init?(touchEvents: [TouchEvent]) {
        guard !touchEvents.isEmpty else { return nil }
        self.confirmedPoints = []
        self.predictedPoints = []
        self.consumable = []
        self.eventToPoint = [:]
        self.eventToIndex = [:]
        self.expectingUpdate = Set()
        self.touchIdentifier = touchEvents.first!.touchIdentifier
        add(touchEvents: touchEvents)
    }

    @discardableResult
    func add(touchEvents: [TouchEvent]) -> MinMaxIndex {
        var indexSet = MinMaxIndex()
        let startingCount = points.count

        for event in touchEvents {
            print("phase: \(event.phase)")
            assert(touchIdentifier == event.touchIdentifier)
            if event.isPrediction {
                assert(!isComplete, "Cannot predict events to a complete pointCollection")
                // The event is a prediction. Attempt to consume a previous prediction and reuse a Point object,
                // otherwise create a new Point and add to the predictions array
                if let prediction = consumable.dequeue() {
                    // This event is a prediction, and we can reuse one of the points from the previous predictions
                    // consume a prediction and reuse it
                    prediction.add(event: event)
                    predictedPoints.append(prediction)
                    let index = confirmedPoints.count + predictedPoints.count - 1
                    indexSet.insert(index)
                } else {
                    // The event is a prediction, and we're out of consumable previous predicted points, so create a new point
                    let prediction = Point(event: event)
                    predictedPoints.append(prediction)
                    let index = confirmedPoints.count + predictedPoints.count - 1
                    indexSet.insert(index)
                }
            } else if
                eventToPoint[event.pointIdentifier] != nil,
                let index = eventToIndex[event.pointIdentifier] {
                // This is an update to an existing point. Add the event to the point that we already have.
                // If this is the last event that the point expects, then remove it from `expectsUpdate`
                eventToPoint[event.pointIdentifier]?.add(event: event)
                if !event.expectsUpdate {
                    expectingUpdate.remove(event.pointIdentifier)
                }
                indexSet.insert(index)

                if event.phase == .ended || event.phase == .cancelled {
                    // this is an update to the final event of the stroke, so remove all predicted points
                    consumable.append(contentsOf: predictedPoints)
                    predictedPoints.removeAll()
                }
            } else if isComplete {
                assert(!isComplete, "Cannot add events to a complete pointCollection")
            } else {
                // we got a new legitimate point. move all of our predictions into consumable
                consumable.append(contentsOf: predictedPoints)
                predictedPoints.removeAll()

                // The event is a normal confirmed user event. Attempt to re-use a consumable point, or create a new Point
                if let point = consumable.dequeue() ?? predictedPoints.dequeue() {
                    // The event is a new confirmed points, consume a previous prediction if possible and update it to the now
                    // confirmed point.
                    if event.expectsUpdate {
                        expectingUpdate.insert(event.pointIdentifier)
                    }
                    point.add(event: event)
                    eventToPoint[event.pointIdentifier] = point
                    confirmedPoints.append(point)
                    let index = confirmedPoints.count - 1
                    eventToIndex[event.pointIdentifier] = index
                    indexSet.insert(index)
                } else {
                    // We are out of consumable points, so create a new point for this event
                    if event.expectsUpdate {
                        expectingUpdate.insert(event.pointIdentifier)
                    }
                    let point = Point(event: event)
                    eventToPoint[event.pointIdentifier] = point
                    confirmedPoints.append(point)
                    let index = confirmedPoints.count - 1
                    eventToIndex[event.pointIdentifier] = index
                    indexSet.insert(index)
                }
            }
        }

        // we might have started with more prodicted touches than we were able to consume
        // in that case, mark the now-out-of-bounds indexes as modified since those points
        // were deleted
        for index in consumable.indices {
            let possiblyRemovedIndex = confirmedPoints.count + predictedPoints.count + index
            if possiblyRemovedIndex < startingCount {
                indexSet.insert(possiblyRemovedIndex)
            } else {
                // this index was only ever seen during this exact update, so we
                // can safely ignore it altogether
                indexSet.remove(possiblyRemovedIndex)
            }
        }

        return indexSet
    }
}

extension TouchPath: Hashable {
    public static func == (lhs: TouchPath, rhs: TouchPath) -> Bool {
        return lhs.touchIdentifier == rhs.touchIdentifier && lhs.points == rhs.points
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(touchIdentifier)
    }
}

extension TouchPath {
    open class Point: Codable {

        public private(set) var events: [TouchEvent]

        public var event: TouchEvent {
            return events.last!
        }

        public var expectsUpdate: Bool {
            return self.event.isPrediction || self.event.expectsUpdate
        }

        public var isPrediction: Bool {
            return events.allSatisfy({ $0.isPrediction })
        }

        public init(event: TouchEvent) {
            events = [event]
            events.reserveCapacity(10)
        }

        func add(event: TouchEvent) {
            events.append(event)
        }
    }
}

extension TouchPath.Point: Hashable {
    public static func == (lhs: TouchPath.Point, rhs: TouchPath.Point) -> Bool {
        return lhs.expectsUpdate == rhs.expectsUpdate && lhs.events == rhs.events
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(events)
    }
}
