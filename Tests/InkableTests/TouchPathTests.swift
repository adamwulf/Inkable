//
//  TouchPathTests.swift
//  InkableTests
//
//  Created by Adam Wulf on 10/27/20.
//

import XCTest
@testable import Inkable

class TouchPathTests: XCTestCase {

    typealias Event = TouchEvent.Simple

    func testJSONEncodeAndDecode() throws {
        let touchId: UITouchIdentifier = UUID().uuidString
        let completeEvents = [Event(id: touchId, loc: CGPoint(x: 100, y: 100), pred: false, update: EstimationUpdateIndex(1)),
                              Event(id: touchId, loc: CGPoint(x: 200, y: 100), pred: true),
                              Event(id: touchId, loc: CGPoint(x: 110, y: 120), pred: false, update: EstimationUpdateIndex(1)),
                              Event(id: touchId, loc: CGPoint(x: 200, y: 100), pred: false, update: EstimationUpdateIndex(2)),
                              Event(id: touchId, loc: CGPoint(x: 220, y: 120), pred: false, update: EstimationUpdateIndex(2))]
        let events = TouchEvent.newFrom(completeEvents)

        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = [.withoutEscapingSlashes, .prettyPrinted]
        guard let json = try? jsonEncoder.encode(events) else { XCTFail("Failed encoding json"); return }
        guard let decodedEvents = try? JSONDecoder().decode([TouchEvent].self, from: json) else { XCTFail("Failed decoding json"); return }

        XCTAssertEqual(events, decodedEvents)
    }

    func testSplitAfterPrediction() throws {
        let touchId: UITouchIdentifier = UUID().uuidString
        let completeEvents = [Event(id: touchId, loc: CGPoint(x: 100, y: 100), pred: false, update: EstimationUpdateIndex(1)),
                              Event(id: touchId, loc: CGPoint(x: 200, y: 100), pred: true),
                              Event(id: touchId, loc: CGPoint(x: 110, y: 120), pred: false, update: EstimationUpdateIndex(1)),
                              Event(id: touchId, loc: CGPoint(x: 200, y: 100), pred: false, update: EstimationUpdateIndex(2)),
                              Event(id: touchId, loc: CGPoint(x: 220, y: 120), pred: false, update: EstimationUpdateIndex(2))]
        let events = TouchEvent.newFrom(completeEvents)

        let touchStream = TouchPathStream()
        let output = touchStream.produce(with: events)

        XCTAssertEqual(output.deltas.count, 2)
        XCTAssertEqual(output.deltas[0], .addedTouchPath(index: 0))
        XCTAssertEqual(output.deltas[1], .completedTouchPath(index: 0))

        let altStream = TouchPathStream()
        let altOutput1 = altStream.produce(with: Array(events[0 ..< 2]))
        let altOutput2 = altStream.produce(with: Array(events[2...]))

        XCTAssertEqual(altOutput1.deltas.count, 1)
        XCTAssertEqual(altOutput1.deltas[0], .addedTouchPath(index: 0))

        XCTAssertEqual(altOutput2.deltas.count, 2)
        XCTAssertEqual(altOutput2.deltas[0], .updatedTouchPath(index: 0, updatedIndexes: IndexSet([0, 1])))
        XCTAssertEqual(altOutput2.deltas[1], .completedTouchPath(index: 0))

        XCTAssertEqual(touchStream.paths, altStream.paths)
    }

    func testStreamsMatch() throws {
        let touchId: UITouchIdentifier = UUID().uuidString
        let completeEvents = [Event(id: touchId, loc: CGPoint(x: 100, y: 100), pred: false, update: EstimationUpdateIndex(1)),
                              Event(id: touchId, loc: CGPoint(x: 200, y: 100), pred: true),
                              Event(id: touchId, loc: CGPoint(x: 110, y: 120), pred: false, update: EstimationUpdateIndex(1)),
                              Event(id: touchId, loc: CGPoint(x: 200, y: 100), pred: false, update: EstimationUpdateIndex(2)),
                              Event(id: touchId, loc: CGPoint(x: 220, y: 120), pred: false, update: EstimationUpdateIndex(2))]
        let events = TouchEvent.newFrom(completeEvents)

        let touchStream = TouchPathStream()
        touchStream.produce(with: events)

        for split in 1..<events.count {
            let altStream = TouchPathStream()
            altStream.produce(with: Array(events[0 ..< split]))
            altStream.produce(with: Array(events[split ..< events.count]))

            XCTAssertEqual(touchStream.paths, altStream.paths, "match fails in split(\(split)))")
        }
    }

    func testMeasureTouchEvents() throws {
        guard
            let jsonFile = Bundle.module.url(forResource: "events", withExtension: "json")
        else {
            XCTFail("Could not load json")
            return
        }

        let data = try Data(contentsOf: jsonFile)
        let events = try JSONDecoder().decode([TouchEvent].self, from: data)

        measure {
            let touchStream = TouchPathStream()
            let midPoint = events.count / 2
            touchStream.produce(with: Array(events[0 ..< midPoint]))
            touchStream.produce(with: Array(events[midPoint...]))
        }
    }

    func testStreamsMatch3() throws {
        let touchId: UITouchIdentifier = UUID().uuidString
        let completeEvents = [Event(id: touchId, loc: CGPoint(x: 100, y: 100), pred: false, update: EstimationUpdateIndex(1)),
                              Event(id: touchId, loc: CGPoint(x: 200, y: 100), pred: true),
                              Event(id: touchId, loc: CGPoint(x: 300, y: 100), pred: true),
                              Event(id: touchId, loc: CGPoint(x: 110, y: 120), pred: false, update: EstimationUpdateIndex(1)),
                              Event(id: touchId, loc: CGPoint(x: 200, y: 100), pred: false, update: EstimationUpdateIndex(2)),
                              Event(id: touchId, loc: CGPoint(x: 220, y: 120), pred: false, update: EstimationUpdateIndex(2)),
                              Event(id: touchId, loc: CGPoint(x: 320, y: 120), pred: false)]
        let events = TouchEvent.newFrom(completeEvents)

        let touchStream = TouchPathStream()
        touchStream.produce(with: events)

        for split in 2..<events.count {
            let altStream = TouchPathStream()
            altStream.produce(with: Array(events[0 ..< split]))
            altStream.produce(with: Array(events[split ..< events.count]))

            XCTAssertEqual(touchStream.paths, altStream.paths)
        }
    }

    func testRemovePredicted() throws {
        let touchId: UITouchIdentifier = UUID().uuidString
        let completeEvents = [Event(id: touchId, loc: CGPoint(x: 100, y: 100), pred: false, update: EstimationUpdateIndex(1)),
                              Event(id: touchId, loc: CGPoint(x: 200, y: 100), pred: true),
                              Event(id: touchId, loc: CGPoint(x: 300, y: 100), pred: true),
                              Event(id: touchId, loc: CGPoint(x: 110, y: 120), pred: false, update: EstimationUpdateIndex(1))]
        let events = TouchEvent.newFrom(completeEvents)
        let touchStream = TouchPathStream()
        let output = touchStream.produce(with: events)

        XCTAssertEqual(output.deltas.count, 2)
        XCTAssertEqual(output.deltas[0], .addedTouchPath(index: 0))
        XCTAssertEqual(output.deltas[1], .completedTouchPath(index: 0))

        let altStream = TouchPathStream()
        let altOutput1 = altStream.produce(with: Array(events[0 ... 2]))
        let altOutput2 = altStream.produce(with: Array(events[3...]))

        XCTAssertEqual(altOutput1.deltas.count, 1)
        XCTAssertEqual(altOutput1.deltas[0], .addedTouchPath(index: 0))

        XCTAssertEqual(altOutput2.deltas.count, 2)
        XCTAssertEqual(altOutput2.deltas[0], .updatedTouchPath(index: 0, updatedIndexes: IndexSet([0, 1, 2])))
        XCTAssertEqual(altOutput2.deltas[1], .completedTouchPath(index: 0))

        XCTAssertEqual(altOutput2.paths.count, 1)
        XCTAssertEqual(altOutput2.paths[0].points.count, 1)

        XCTAssertEqual(touchStream.paths, altStream.paths)
    }

    func testCorrectPointCountAndLocation() throws {
        let touchId: UITouchIdentifier = UUID().uuidString
        let completeEvents = [Event(id: touchId, loc: CGPoint(x: 100, y: 100), pred: false, update: EstimationUpdateIndex(1)),
                              Event(id: touchId, loc: CGPoint(x: 200, y: 100), pred: true),
                              Event(id: touchId, loc: CGPoint(x: 110, y: 120), pred: false, update: EstimationUpdateIndex(1)),
                              Event(id: touchId, loc: CGPoint(x: 200, y: 110), pred: false, update: EstimationUpdateIndex(2)),
                              Event(id: touchId, loc: CGPoint(x: 220, y: 120), pred: false, update: EstimationUpdateIndex(2))]
        var events = TouchEvent.newFrom(completeEvents)

        let touchStream = TouchPathStream()
        var output = touchStream.produce(with: [events.removeFirst()])

        XCTAssertEqual(output.paths.count, 1)
        XCTAssertEqual(output.paths[0].touchIdentifier, touchId)
        XCTAssertEqual(output.paths[0].isComplete, false)
        XCTAssertEqual(output.paths[0].points.count, 1)
        XCTAssertEqual(output.paths[0].points[0].events.count, 1)
        XCTAssertEqual(output.paths[0].points[0].event.location, CGPoint(x: 100, y: 100))

        output = touchStream.produce(with: [events.removeFirst()])

        XCTAssertEqual(output.paths.count, 1)
        XCTAssertEqual(output.paths[0].isComplete, false)
        XCTAssertEqual(output.paths[0].points.count, 2)
        XCTAssertEqual(output.paths[0].points[0].events.count, 1)
        XCTAssertEqual(output.paths[0].points[0].event.location, CGPoint(x: 100, y: 100))
        XCTAssertEqual(output.paths[0].points[1].events.count, 1)
        XCTAssertEqual(output.paths[0].points[1].event.location, CGPoint(x: 200, y: 100))

        output = touchStream.produce(with: [events.removeFirst(), events.removeFirst()])

        XCTAssertEqual(output.paths.count, 1)
        XCTAssertEqual(output.paths[0].isComplete, false)
        XCTAssertEqual(output.paths[0].points.count, 2)
        XCTAssertEqual(output.paths[0].points[0].events.count, 2)
        XCTAssertEqual(output.paths[0].points[0].event.location, CGPoint(x: 110, y: 120))
        XCTAssertEqual(output.paths[0].points[1].events.count, 2)
        XCTAssertEqual(output.paths[0].points[1].event.location, CGPoint(x: 200, y: 110))

        output = touchStream.produce(with: [events.removeFirst()])

        XCTAssertEqual(output.paths.count, 1)
        XCTAssertEqual(output.paths[0].isComplete, true)
        XCTAssertEqual(output.paths[0].points.count, 2)
        XCTAssertEqual(output.paths[0].points[0].events.count, 2)
        XCTAssertEqual(output.paths[0].points[0].event.location, CGPoint(x: 110, y: 120))
        XCTAssertEqual(output.paths[0].points[1].events.count, 3)
        XCTAssertEqual(output.paths[0].points[1].event.location, CGPoint(x: 220, y: 120))
    }

    func testCorrectPointSplitPrediction() throws {
        let touchId: UITouchIdentifier = UUID().uuidString
        let completeEvents = [Event(id: touchId, loc: CGPoint(x: 100, y: 100), pred: false, update: EstimationUpdateIndex(1)),
                              Event(id: touchId, loc: CGPoint(x: 200, y: 100), pred: true),
                              Event(id: touchId, loc: CGPoint(x: 300, y: 100), pred: true),
                              Event(id: touchId, loc: CGPoint(x: 110, y: 120), pred: false, update: EstimationUpdateIndex(1)),
                              Event(id: touchId, loc: CGPoint(x: 200, y: 110), pred: false, update: EstimationUpdateIndex(2)),
                              Event(id: touchId, loc: CGPoint(x: 220, y: 120), pred: false, update: EstimationUpdateIndex(2))]
        var events = TouchEvent.newFrom(completeEvents)

        let touchStream = TouchPathStream()
        var output = touchStream.produce(with: [events.removeFirst()])

        XCTAssertEqual(output.paths.count, 1)
        XCTAssertEqual(output.paths[0].touchIdentifier, touchId)
        XCTAssertEqual(output.paths[0].isComplete, false)
        XCTAssertEqual(output.paths[0].points.count, 1)
        XCTAssertEqual(output.paths[0].points[0].events.count, 1)
        XCTAssertEqual(output.paths[0].points[0].event.location, CGPoint(x: 100, y: 100))

        output = touchStream.produce(with: [events.removeFirst()])

        XCTAssertEqual(output.paths.count, 1)
        XCTAssertEqual(output.paths[0].isComplete, false)
        XCTAssertEqual(output.paths[0].points.count, 2)
        XCTAssertEqual(output.paths[0].points[0].events.count, 1)
        XCTAssertEqual(output.paths[0].points[0].event.location, CGPoint(x: 100, y: 100))
        XCTAssertEqual(output.paths[0].points[1].events.count, 1)
        XCTAssertEqual(output.paths[0].points[1].event.location, CGPoint(x: 200, y: 100))

        output = touchStream.produce(with: [events.removeFirst()])

        XCTAssertEqual(output.paths.count, 1)
        XCTAssertEqual(output.paths[0].isComplete, false)
        XCTAssertEqual(output.paths[0].points.count, 3)
        XCTAssertEqual(output.paths[0].points[0].events.count, 1)
        XCTAssertEqual(output.paths[0].points[0].event.location, CGPoint(x: 100, y: 100))
        XCTAssertEqual(output.paths[0].points[1].events.count, 1)
        XCTAssertEqual(output.paths[0].points[1].event.location, CGPoint(x: 200, y: 100))
        XCTAssertEqual(output.paths[0].points[2].events.count, 1)
        XCTAssertEqual(output.paths[0].points[2].event.location, CGPoint(x: 300, y: 100))

        // consume 2 events
        output = touchStream.produce(with: [events.removeFirst(), events.removeFirst()])

        XCTAssertEqual(output.paths.count, 1)
        XCTAssertEqual(output.paths[0].isComplete, false)
        XCTAssertEqual(output.paths[0].points.count, 2)
        XCTAssertEqual(output.paths[0].points[0].events.count, 2)
        XCTAssertEqual(output.paths[0].points[0].event.location, CGPoint(x: 110, y: 120))
        XCTAssertEqual(output.paths[0].points[1].events.count, 2)
        XCTAssertEqual(output.paths[0].points[1].event.location, CGPoint(x: 200, y: 110))

        output = touchStream.produce(with: [events.removeFirst()])

        XCTAssertEqual(output.paths.count, 1)
        XCTAssertEqual(output.paths[0].isComplete, true)
        XCTAssertEqual(output.paths[0].points.count, 2)
        XCTAssertEqual(output.paths[0].points[0].events.count, 2)
        XCTAssertEqual(output.paths[0].points[0].event.location, CGPoint(x: 110, y: 120))
        XCTAssertEqual(output.paths[0].points[1].events.count, 3)
        XCTAssertEqual(output.paths[0].points[1].event.location, CGPoint(x: 220, y: 120))
    }

    // Input:
    // event batch 1 contains (0..<3):
    //     a) a point expecting a location update
    //     b) a predicted point
    //     c) an update to the (a) point, finishing this point (the predicted point (b) remains)
    // event batch 2 contains (3..<6):
    //     a) a new path 2 begins with a fresh point
    //     b) a new prediction for path 2
    //     c) an update to 2.a (prediction 2.b remains)
    // event batch 3 contains:
    //     a) one new point per path, along with an update to that new point. Each of these consume the prediction from batch 2
    func testCorrectPointsMultipleLines() throws {
        let touchId1: UITouchIdentifier = UUID().uuidString
        let touchId2: UITouchIdentifier = UUID().uuidString
        let completeEvents = [Event(id: touchId1, loc: CGPoint(x: 100, y: 100), pred: false, update: EstimationUpdateIndex(3)),
                              Event(id: touchId1, loc: CGPoint(x: 200, y: 100), pred: true),
                              Event(id: touchId1, loc: CGPoint(x: 110, y: 120), pred: false, update: EstimationUpdateIndex(3)),

                              Event(id: touchId2, loc: CGPoint(x: 100, y: 100), pred: false, update: EstimationUpdateIndex(1)),
                              Event(id: touchId2, loc: CGPoint(x: 200, y: 100), pred: true),
                              Event(id: touchId2, loc: CGPoint(x: 110, y: 120), pred: false, update: EstimationUpdateIndex(1)),

                              Event(id: touchId1, loc: CGPoint(x: 200, y: 110), pred: false, update: EstimationUpdateIndex(2)),
                              Event(id: touchId1, loc: CGPoint(x: 220, y: 120), pred: false, update: EstimationUpdateIndex(2)),
                              Event(id: touchId2, loc: CGPoint(x: 200, y: 110), pred: false, update: EstimationUpdateIndex(4)),
                              Event(id: touchId2, loc: CGPoint(x: 220, y: 120), pred: false, update: EstimationUpdateIndex(4))]
        let events = TouchEvent.newFrom(completeEvents)

        let touchStream = TouchPathStream()
        var output = touchStream.produce(with: Array(events[0 ..< 3]))

        XCTAssertEqual(output.paths.count, 1)
        XCTAssertEqual(output.paths[0].touchIdentifier, touchId1)
        XCTAssertEqual(output.paths[0].isComplete, false)
        XCTAssertEqual(output.paths[0].points.count, 2)
        XCTAssertEqual(output.paths[0].points[0].events.count, 2)
        XCTAssertEqual(output.paths[0].points[0].event.location, CGPoint(x: 110, y: 120))
        XCTAssertEqual(output.paths[0].points[1].event.location, CGPoint(x: 200, y: 100))
        XCTAssertTrue(output.paths[0].points[1].isPrediction)

        XCTAssertEqual(output.deltas.count, 1)
        XCTAssertEqual(output.deltas[0], .addedTouchPath(index: 0))

        output = touchStream.produce(with: Array(events[3 ..< 6]))

        XCTAssertEqual(output.paths.count, 2)
        XCTAssertEqual(output.paths[1].touchIdentifier, touchId2)
        XCTAssertEqual(output.paths[1].isComplete, false)
        XCTAssertEqual(output.paths[1].points.count, 2)
        XCTAssertEqual(output.paths[1].points[0].events.count, 2)
        XCTAssertEqual(output.paths[1].points[0].event.location, CGPoint(x: 110, y: 120))
        XCTAssertEqual(output.paths[1].points[1].event.location, CGPoint(x: 200, y: 100))
        XCTAssertTrue(output.paths[1].points[1].isPrediction)

        XCTAssertEqual(output.deltas.count, 1)
        XCTAssertEqual(output.deltas[0], .addedTouchPath(index: 1))

        output = touchStream.produce(with: Array(events[6...]))

        XCTAssertEqual(output.paths.count, 2)
        XCTAssertEqual(output.paths[0].isComplete, true)
        XCTAssertEqual(output.paths[0].points.count, 2)
        XCTAssertEqual(output.paths[0].points[0].events.count, 2)
        XCTAssertEqual(output.paths[0].points[0].event.location, CGPoint(x: 110, y: 120))
        XCTAssertEqual(output.paths[0].points[1].events.count, 3)
        XCTAssertEqual(output.paths[0].points[1].event.location, CGPoint(x: 220, y: 120))

        XCTAssertEqual(output.paths[1].isComplete, true)
        XCTAssertEqual(output.paths[1].points.count, 2)
        XCTAssertEqual(output.paths[1].points[0].events.count, 2)
        XCTAssertEqual(output.paths[1].points[0].event.location, CGPoint(x: 110, y: 120))
        XCTAssertEqual(output.paths[1].points[1].events.count, 3)
        XCTAssertEqual(output.paths[1].points[1].event.location, CGPoint(x: 220, y: 120))

        XCTAssertEqual(output.deltas.count, 4)
        XCTAssertEqual(output.deltas[0], .updatedTouchPath(index: 0, updatedIndexes: IndexSet([1])))
        XCTAssertEqual(output.deltas[1], .completedTouchPath(index: 0))
        XCTAssertEqual(output.deltas[2], .updatedTouchPath(index: 1, updatedIndexes: IndexSet([1])))
        XCTAssertEqual(output.deltas[3], .completedTouchPath(index: 1))
    }
}
