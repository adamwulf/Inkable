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
        let smoother = BezierElementStream(smoother: AntigrainSmoother())
        touchStream.addConsumer(polylineStream)
        polylineStream.addConsumer(smoother)
        touchStream.produce(with: events)

        for split in 1..<events.count {
            let altStream = TouchPathStream()
            let altPolylineStream = PolylineStream()
            let altSmoother = BezierElementStream(smoother: AntigrainSmoother())
            altStream.addConsumer(altPolylineStream)
            altPolylineStream.addConsumer(altSmoother)
            altStream.produce(with: Array(events[0 ..< split]))
            altStream.produce(with: Array(events[split ..< events.count]))

            XCTAssertEqual(touchStream.paths, altStream.paths)
            XCTAssertEqual(polylineStream.lines, altPolylineStream.lines)
            XCTAssertEqual(smoother.beziers, altSmoother.beziers)
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
        let smoother = BezierElementStream(smoother: AntigrainSmoother())
        touchStream.addConsumer(polylineStream)
        polylineStream.addConsumer(smoother)
        touchStream.produce(with: events)

        for split in 1..<events.count {
            let altStream = TouchPathStream()
            let altPolylineStream = PolylineStream()
            let altSmoother = BezierElementStream(smoother: AntigrainSmoother())
            altStream.addConsumer(altPolylineStream)
            altPolylineStream.addConsumer(altSmoother)
            altStream.produce(with: Array(events[0 ..< split]))
            altStream.produce(with: Array(events[split ..< events.count]))

            XCTAssertEqual(touchStream.paths, altStream.paths)
            XCTAssertEqual(polylineStream.lines, altPolylineStream.lines)
            XCTAssertEqual(smoother.beziers, altSmoother.beziers, "error at split index \(split)")
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
        let smoother = BezierElementStream(smoother: AntigrainSmoother())
        touchStream.addConsumer(polylineStream)
        polylineStream.addConsumer(smoother)
        touchStream.produce(with: events)

        for split in 1..<events.count {
            let altStream = TouchPathStream()
            let altPolylineStream = PolylineStream()
            let altSmoother = BezierElementStream(smoother: AntigrainSmoother())
            altStream.addConsumer(altPolylineStream)
            altPolylineStream.addConsumer(altSmoother)
            altStream.produce(with: Array(events[0 ..< split]))
            altStream.produce(with: Array(events[split ..< events.count]))

            XCTAssertEqual(touchStream.paths, altStream.paths)
            XCTAssertEqual(polylineStream.lines, altPolylineStream.lines)
            XCTAssertEqual(smoother.beziers, altSmoother.beziers)
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
        let smoother = BezierElementStream(smoother: AntigrainSmoother())
        touchStream.addConsumer(polylineStream)
        polylineStream.addConsumer(smoother)
        touchStream.produce(with: events)

        for split in 1..<events.count {
            let altStream = TouchPathStream()
            let altPolylineStream = PolylineStream()
            let altSmoother = BezierElementStream(smoother: AntigrainSmoother())
            altStream.addConsumer(altPolylineStream)
            altPolylineStream.addConsumer(altSmoother)
            altStream.produce(with: Array(events[0 ..< split]))
            altStream.produce(with: Array(events[split ..< events.count]))

            XCTAssertEqual(touchStream.paths, altStream.paths)
            XCTAssertEqual(polylineStream.lines, altPolylineStream.lines)
            XCTAssertEqual(smoother.beziers, altSmoother.beziers)
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
        let smoother = BezierElementStream(smoother: AntigrainSmoother())
        touchStream.addConsumer(polylineStream)
        polylineStream.addConsumer(smoother)
        touchStream.produce(with: events)

        for split in 1..<events.count {
            let altStream = TouchPathStream()
            let altPolylineStream = PolylineStream()
            let altSmoother = BezierElementStream(smoother: AntigrainSmoother())
            altStream.addConsumer(altPolylineStream)
            altPolylineStream.addConsumer(altSmoother)
            altStream.produce(with: Array(events[0 ..< split]))
            altStream.produce(with: Array(events[split ..< events.count]))

            XCTAssertEqual(touchStream.paths, altStream.paths)
            XCTAssertEqual(polylineStream.lines, altPolylineStream.lines)
            XCTAssertEqual(smoother.beziers, altSmoother.beziers)
        }
    }
}
