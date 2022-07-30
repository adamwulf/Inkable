//
//  BezierStreamTests.swift
//  InkableTests
//
//  Created by Adam Wulf on 4/8/21.
//

import XCTest
@testable import Inkable

class BezierStreamTests: XCTestCase {

    func testSimpleBezierPath() throws {
        let completeEvents = [Event(x: 100, y: 100),
                              Event(x: 110, y: 110),
                              Event(x: 120, y: 160),
                              Event(x: 130, y: 120),
                              Event(x: 140, y: 120),
                              Event(x: 150, y: 110)]
        let points = Polyline.Point.newFrom(completeEvents)
        let line = Polyline(points: points)
        let polylineOutput = PolylineStream.Produces(lines: [line], deltas: [.addedPolyline(index: 0)])

        let bezierStream = BezierStream(smoother: AntigrainSmoother())

        let bezierOutput = bezierStream.produce(with: polylineOutput)

        XCTAssert(polylineOutput.lines[0] == bezierOutput.paths[0])
        XCTAssertEqual(bezierOutput.deltas[0], .addedBezierPath(index: 0))
    }

    func testGeneratedLines() throws {
        let simpleEvents = Event.events(from: CGPoint(x: 100, y: 100), to: CGPoint(x: 200, y: 100))
        let touchEvents = TouchEvent.newFrom(simpleEvents)

        let touchPathStream = TouchPathStream()
        let polylineStream = PolylineStream()
        let bezierStream = BezierStream(smoother: AntigrainSmoother())

        let touchPathOutput = touchPathStream.produce(with: touchEvents)
        let polylineOutput = polylineStream.produce(with: touchPathOutput)
        let bezierOutput = bezierStream.produce(with: polylineOutput)

        XCTAssertEqual(bezierOutput.paths.count, 1)
        XCTAssertEqual(bezierOutput.deltas.count, 2)

        XCTAssert(polylineOutput.lines[0] == bezierOutput.paths[0])
        XCTAssertEqual(bezierOutput.deltas[0], .addedBezierPath(index: 0))
        XCTAssertEqual(bezierOutput.deltas[1], .completedBezierPath(index: 0))
    }

    func testUpdatedLines() throws {
        let simpleEvents = Event.events(from: CGPoint(x: 100, y: 100), to: CGPoint(x: 200, y: 100))
        let touchEvents = TouchEvent.newFrom(simpleEvents)

        let touchPathStream = TouchPathStream()
        let bezierStream = BezierStream(smoother: AntigrainSmoother())

        touchPathStream
            .nextStep(PolylineStream())
            .nextStep(bezierStream)

        let firstEvents = Array(touchEvents[0..<5])
        let lastEvents = Array(touchEvents[5...])

        touchPathStream.produce(with: firstEvents)

        guard let output1 = bezierStream.produced else { XCTFail(); return }

        XCTAssertEqual(output1.paths.count, 1)
        XCTAssertEqual(output1.deltas.count, 1)
        XCTAssertEqual(output1.deltas[0], .addedBezierPath(index: 0))

        touchPathStream.produce(with: lastEvents)

        guard let output2 = bezierStream.produced else { XCTFail(); return }

        XCTAssertEqual(output2.paths.count, 1)
        XCTAssertEqual(output2.deltas.count, 2)
        XCTAssertEqual(output2.deltas[0], .updatedBezierPath(index: 0, updatedIndexes: MinMaxIndex(4..<simpleEvents.count)))
        XCTAssertEqual(output2.deltas[1], .completedBezierPath(index: 0))
    }

    // This tests that the BezierStream can remove elements of a path when the input Polyline is truncated to fewer
    // points. This can happen when multiple predicted points are sent, followed by a single final permanent point.
    func testManyPredictions() throws {
        let touchId: UITouchIdentifier = UUID().uuidString
        let completeEvents = [Event(id: touchId, loc: CGPoint(x: 100, y: 100), pred: false),
                              Event(id: touchId, loc: CGPoint(x: 110, y: 110), pred: false),
                              Event(id: touchId, loc: CGPoint(x: 120, y: 120), pred: false),
                              Event(id: touchId, loc: CGPoint(x: 130, y: 130), pred: true, update: EstimationUpdateIndex(1)),
                              Event(id: touchId, loc: CGPoint(x: 140, y: 140), pred: true, update: EstimationUpdateIndex(1)),
                              Event(id: touchId, loc: CGPoint(x: 150, y: 150), pred: true, update: EstimationUpdateIndex(1)),
                              Event(id: touchId, loc: CGPoint(x: 160, y: 160), pred: true, update: EstimationUpdateIndex(1)),
                              Event(id: touchId, loc: CGPoint(x: 170, y: 170), pred: true, update: EstimationUpdateIndex(1)),
                              Event(id: touchId, loc: CGPoint(x: 180, y: 180), pred: true, update: EstimationUpdateIndex(1)),
                              Event(id: touchId, loc: CGPoint(x: 130, y: 130), pred: false)]
        let touchEvents = TouchEvent.newFrom(completeEvents)

        let allElementCount = { () -> Int in
            let touchPathStream = TouchPathStream()
            let polylineStream = PolylineStream()
            let bezierStream = BezierStream(smoother: AntigrainSmoother())

            touchPathStream
                .nextStep(polylineStream)
                .nextStep(bezierStream)
            touchPathStream.consume(touchEvents)
            return bezierStream.paths.first?.elementCount ?? 0
        }()

        let touchPathStream = TouchPathStream()
        let polylineStream = PolylineStream()
        let bezierStream = BezierStream(smoother: AntigrainSmoother())

        touchPathStream
            .nextStep(polylineStream)
            .nextStep(bezierStream)

        let firstEvents = Array(touchEvents[0..<9])
        let lastEvents = Array(touchEvents[9...])

        touchPathStream.produce(with: firstEvents)

        XCTAssertEqual(bezierStream.paths.count, 1)
        XCTAssertEqual(bezierStream.paths[0].elementCount, polylineStream.lines[0].points.count - 1)

        touchPathStream.produce(with: lastEvents)

        XCTAssertEqual(bezierStream.paths.count, 1)
        XCTAssertEqual(bezierStream.paths[0].elementCount, allElementCount)
    }

    func testIsEnabledFlag() throws {
        let completeEvents = [Event(x: 100, y: 100),
                              Event(x: 110, y: 110),
                              Event(x: 120, y: 160),
                              Event(x: 130, y: 120),
                              Event(x: 140, y: 120),
                              Event(x: 150, y: 110)]
        let points = Polyline.Point.newFrom(completeEvents)
        let line = Polyline(points: points)
        let polylineOutput = PolylineStream.Produces(lines: [line], deltas: [.addedPolyline(index: 0)])

        let bezierStream = BezierStream(smoother: AntigrainSmoother())
        bezierStream.isEnabled = false

        var bezierOutput = bezierStream.produce(with: polylineOutput)

        XCTAssert(bezierOutput.paths.isEmpty)
        XCTAssert(bezierOutput.deltas.isEmpty)

        bezierStream.isEnabled = true

        bezierOutput = bezierStream.produced!

        XCTAssert(polylineOutput.lines[0] == bezierOutput.paths[0])
        XCTAssertEqual(bezierOutput.deltas[0], .addedBezierPath(index: 0))
    }
}
