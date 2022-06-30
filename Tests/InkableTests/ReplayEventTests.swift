//
//  ReplayEventTests.swift
//  InkableTests
//
//  Created by Adam Wulf on 10/27/20.
//

import XCTest
@testable import Inkable

class ReplayEventTests: XCTestCase {

    func testEvents() throws {
        guard
            let jsonFile = Bundle.module.url(forResource: "events", withExtension: "json")
        else {
            XCTFail("Could not load json")
            return
        }

        let data = try Data(contentsOf: jsonFile)
        let events = try JSONDecoder().decode([TouchEvent].self, from: data)
        let touchStream = TouchPathStream()
        let polylineStream = PolylineStream()
        let smoother = BezierStream(smoother: AntigrainSmoother())
        touchStream.addConsumer(polylineStream)
        polylineStream.addConsumer(smoother)
        touchStream.produce(with: events)

        for split in 1..<events.count {
            let altStream = TouchPathStream()
            let altPolylineStream = PolylineStream()
            let altSmoother = BezierStream(smoother: AntigrainSmoother())
            altStream.addConsumer(altPolylineStream)
            altPolylineStream.addConsumer(altSmoother)
            altStream.produce(with: Array(events[0 ..< split]))
            altStream.produce(with: Array(events[split ..< events.count]))

            XCTAssertEqual(touchStream.paths, altStream.paths)
            XCTAssertEqual(polylineStream.lines, altPolylineStream.lines)
            XCTAssertEqual(smoother.paths, altSmoother.paths)
        }
    }

    func testPencilAntigrain() throws {
        guard
            let jsonFile = Bundle.module.url(forResource: "pencil-antigrain", withExtension: "json")
        else {
            XCTFail("Could not load json")
            return
        }

        let data = try Data(contentsOf: jsonFile)
        let events = try JSONDecoder().decode([TouchEvent].self, from: data)
        let touchStream = TouchPathStream()
        let polylineStream = PolylineStream()
        let smoother = BezierStream(smoother: AntigrainSmoother())
        touchStream.addConsumer(polylineStream)
        polylineStream.addConsumer(smoother)
        touchStream.produce(with: events)

        for split in 1..<events.count {
            let altStream = TouchPathStream()
            let altPolylineStream = PolylineStream()
            let altSmoother = BezierStream(smoother: AntigrainSmoother())
            altStream.addConsumer(altPolylineStream)
            altPolylineStream.addConsumer(altSmoother)
            altStream.produce(with: Array(events[0 ..< split]))
            altStream.produce(with: Array(events[split ..< events.count]))

            if touchStream.paths != altStream.paths {
                print("gotcha")
            }

            if smoother.paths != altSmoother.paths {
                print("gotcha") // path length is different
                // I believe the issue is that the smoother can't currently remove path elements
                // so when multiple predicted points are added, it'll add elements for each,
                // but then if only 1 point replaces them then it'll have too many elements
            }

            XCTAssertEqual(touchStream.paths, altStream.paths)
            XCTAssertEqual(polylineStream.lines, altPolylineStream.lines)
            XCTAssertEqual(smoother.paths, altSmoother.paths)
        }
    }

    func testPencilAntigrain2() throws {
        guard
            let jsonFile = Bundle.module.url(forResource: "pencil-antigrain2", withExtension: "json")
        else {
            XCTFail("Could not load json")
            return
        }

        let data = try Data(contentsOf: jsonFile)
        let events = try JSONDecoder().decode([TouchEvent].self, from: data)
        let touchStream = TouchPathStream()
        let polylineStream = PolylineStream()
        let smoother = BezierStream(smoother: AntigrainSmoother())
        touchStream.addConsumer(polylineStream)
        polylineStream.addConsumer(smoother)
        touchStream.produce(with: events)

        for split in 1..<events.count {
            let altStream = TouchPathStream()
            let altPolylineStream = PolylineStream()
            let altSmoother = BezierStream(smoother: AntigrainSmoother())
            altStream.addConsumer(altPolylineStream)
            altPolylineStream.addConsumer(altSmoother)
            altStream.produce(with: Array(events[0 ..< split]))
            altStream.produce(with: Array(events[split ..< events.count]))

            XCTAssertEqual(touchStream.paths, altStream.paths)
            XCTAssertEqual(polylineStream.lines, altPolylineStream.lines)
            XCTAssertEqual(smoother.paths, altSmoother.paths)
        }
    }

    func testPencilError() throws {
        guard
            let jsonFile = Bundle.module.url(forResource: "pencil-error", withExtension: "json")
        else {
            XCTFail("Could not load json")
            return
        }

        let data = try Data(contentsOf: jsonFile)
        let events = try JSONDecoder().decode([TouchEvent].self, from: data)
        let touchStream = TouchPathStream()
        let polylineStream = PolylineStream()
        let smoother = BezierStream(smoother: AntigrainSmoother())
        touchStream.addConsumer(polylineStream)
        polylineStream.addConsumer(smoother)
        touchStream.produce(with: events)

        for split in 1..<events.count {
            let altStream = TouchPathStream()
            let altPolylineStream = PolylineStream()
            let altSmoother = BezierStream(smoother: AntigrainSmoother())
            altStream.addConsumer(altPolylineStream)
            altPolylineStream.addConsumer(altSmoother)
            altStream.produce(with: Array(events[0 ..< split]))
            altStream.produce(with: Array(events[split ..< events.count]))

            XCTAssertEqual(touchStream.paths, altStream.paths)
            XCTAssertEqual(polylineStream.lines, altPolylineStream.lines)
            XCTAssertEqual(smoother.paths, altSmoother.paths)
        }
    }

    func testUnknownPolylineIndex() throws {
        guard
            let jsonFile = Bundle.module.url(forResource: "unknown-polyline-index", withExtension: "json")
        else {
            XCTFail("Could not load json")
            return
        }

        let data = try Data(contentsOf: jsonFile)
        let events = try JSONDecoder().decode([TouchEvent].self, from: data)
        let touchStream = TouchPathStream()
        let polylineStream = PolylineStream()
        let smoother = BezierStream(smoother: AntigrainSmoother())
        touchStream.addConsumer(polylineStream)
        polylineStream.addConsumer(smoother)
        touchStream.produce(with: events)

        for split in 1..<events.count {
            let altStream = TouchPathStream()
            let altPolylineStream = PolylineStream()
            let altSmoother = BezierStream(smoother: AntigrainSmoother())
            altStream.addConsumer(altPolylineStream)
            altPolylineStream.addConsumer(altSmoother)
            altStream.produce(with: Array(events[0 ..< split]))
            altStream.produce(with: Array(events[split ..< events.count]))

            XCTAssertEqual(touchStream.paths, altStream.paths)
            XCTAssertEqual(polylineStream.lines, altPolylineStream.lines)
            XCTAssertEqual(smoother.paths, altSmoother.paths)
        }
    }
}
