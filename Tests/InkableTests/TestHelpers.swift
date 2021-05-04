//
//  TouchEvent+TestHelpers.swift
//  InkableTests
//
//  Created by Adam Wulf on 10/27/20.
//

import UIKit
@testable import Inkable
@testable import MMSwiftToolbox

typealias Event = TouchEvent.Simple

extension Array where Element: Equatable {
    // Remove first collection element that is equal to the given `object`:
    mutating func remove(_ object: Element) {
        guard let index = firstIndex(of: object) else {return}
        remove(at: index)
    }
}

extension Array where Element == TouchEvent.Simple {
    func phased() -> [TouchEvent.Phased] {
        var phaseEvents = self.map { (completeEvent) -> TouchEvent.Phased in
            return TouchEvent.Phased(event: completeEvent, phase: .moved, updatePhase: nil)
        }
        // find the .began and .ended events per touchIdentifier
        var soFar: [UITouchIdentifier] = []
        for index in phaseEvents.indices {
            let phased = phaseEvents[index]
            if !soFar.contains(phased.event.id),
               !phased.event.pred {
                soFar.append(phased.event.id)
                phaseEvents[index].phase = .began
            }
        }
        for index in phaseEvents.indices.reversed() {
            let phased = phaseEvents[index]
            if soFar.contains(phased.event.id),
               phased.phase == .moved,
               !phased.event.pred {
                soFar.remove(phased.event.id)
                phaseEvents[index].phase = .ended
            }
        }
        // Find all indices for every updated TouchEvent
        var estIndices: [EstimationUpdateIndex: NSMutableIndexSet] = [:]
        for index in phaseEvents.indices {
            if let estInd = phaseEvents[index].event.update {
                let indices = estIndices[estInd] ?? NSMutableIndexSet()
                indices.add(index)
                estIndices[estInd] = indices
            }
        }

        for estInd in estIndices.indices {
            let eventIndexes = estIndices[estInd].value
            for index in eventIndexes {
                phaseEvents[index].updatePhase = .moved
            }
            phaseEvents[eventIndexes.firstIndex].updatePhase = .began
            phaseEvents[eventIndexes.lastIndex].updatePhase = .ended
        }

        return phaseEvents
    }
}

extension Array where Element == TouchEvent {
    func matches(_ phased: [TouchEvent.Phased]) -> Bool {
        guard count == phased.count else { return false }
        for index in phased.indices {
            let lhs = self[index]
            let rhs = phased[index]
            guard lhs.phase == rhs.phase && lhs.location == rhs.event.loc && lhs.touchIdentifier == rhs.event.id else { return false }
        }
        return true
    }

    func having(id: UITouchIdentifier) -> [TouchEvent] {
        return filter({ $0.touchIdentifier == id })
    }
}

extension Array where Element == TouchEvent {
    func matches(_ simple: [TouchEvent.Simple]) -> Bool {
        return matches(simple.phased())
    }
}

extension TouchEvent {

    struct Simple {
        let id: UITouchIdentifier
        let loc: CGPoint
        let pred: Bool
        let update: EstimationUpdateIndex?

        init(id: UITouchIdentifier = UUID().uuidString, loc: CGPoint, pred: Bool? = nil, update: EstimationUpdateIndex? = nil) {
            self.id = id
            self.loc = loc
            self.pred = pred ?? false
            self.update = update
        }

        init(x: CGFloat, y: CGFloat) {
            self.init(loc: CGPoint(x: x, y: y))
        }
    }

    typealias Phased = (event: Simple, phase: UITouch.Phase, updatePhase: UITouch.Phase?)

    static func newFrom(_ completeEvents: [Simple]) -> [TouchEvent] {
        let phaseEvents = completeEvents.phased()

        return phaseEvents.map { (phaseEvent) -> TouchEvent in
            let hasUpdate = phaseEvent.updatePhase != nil
            return TouchEvent(touchIdentifier: phaseEvent.event.id,
                       type: .direct,
                       phase: phaseEvent.phase,
                       location: phaseEvent.event.loc,
                       estimationUpdateIndex: phaseEvent.event.update,
                       estimatedProperties: hasUpdate ? .location : .none,
                       estimatedPropertiesExpectingUpdates: hasUpdate && phaseEvent.updatePhase != .ended ? .location : .none,
                       isUpdate: hasUpdate && phaseEvent.updatePhase != .began,
                       isPrediction: phaseEvent.event.pred)
        }
    }
}

extension TouchEvent.Simple {
    static func events(from start: CGPoint, to end: CGPoint, step: CGFloat = 10) -> [TouchEvent.Simple] {
        let touchId: UITouchIdentifier = UUID().uuidString
        let startEvent = Event(id: touchId, loc: start)
        let endEvent = Event(id: touchId, loc: end)
        guard step > 0 else {
            return [startEvent, endEvent]
        }

        let dist = start.distance(to: end)
        let vec = (end - start).normalize(to: step)

        var events = [startEvent]
        var previous = start
        for _ in 0 ..< Int(dist / step) {
            let next = previous + vec
            events.append(Event(id: touchId, loc: next))
            previous = next
        }
        if let last = events.last?.loc,
           end != last {
            events.append(endEvent)
        }

        return events
    }
}

extension TouchPath.Point {
    static func newFrom(_ simpleEvents: [TouchEvent.Simple]) -> [TouchPath.Point] {
        let events = TouchEvent.newFrom(simpleEvents)
        return events.map({ TouchPath.Point(event: $0) })
    }
}

extension Polyline.Point {
    static func newFrom(_ simpleEvents: [TouchEvent.Simple]) -> [Polyline.Point] {
        let points = TouchPath.Point.newFrom(simpleEvents)
        return points.map({ Polyline.Point(touchPoint: $0) })
    }
}

extension Polyline {
    // Assert that the defined points along the Polyline align exactly with
    // the element endpoints along the Bezier path.
    static func == (lhs: Polyline, rhs: UIBezierPath) -> Bool {
        guard lhs.points.count == rhs.elementCount else { return false }
        for (i, point) in lhs.points.enumerated() {
            guard point.location == rhs.pointOnPath(atElement: i, andTValue: 1) else {
                return false
            }
        }
        return true
    }
}
