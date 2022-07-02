//
//  SavitzkyGolayTests.swift
//  
//
//  Created by Adam Wulf on 7/1/22.
//

import XCTest
@testable import Inkable

class SavitzkyGolayTests: XCTestCase {

    func testSimpleSmoothing() throws {
        let touchId: UITouchIdentifier = UUID().uuidString
        let completeEvents = [Event(id: touchId, loc: CGPoint(x: 100, y: 100), pred: false),
                              Event(id: touchId, loc: CGPoint(x: 110, y: 105), pred: false),
                              Event(id: touchId, loc: CGPoint(x: 120, y: 108), pred: false),
                              Event(id: touchId, loc: CGPoint(x: 125, y: 112), pred: false),
                              Event(id: touchId, loc: CGPoint(x: 140, y: 116), pred: false),
                              Event(id: touchId, loc: CGPoint(x: 150, y: 116), pred: false)]
        let touchEvents = TouchEvent.newFrom(completeEvents)
        let touchStream = TouchPathStream()
        let polylineStream = PolylineStream()
        let smoothing = NaiveSavitzkyGolay()

        touchStream.nextStep(polylineStream).nextStep(smoothing)
        touchStream.produce(with: touchEvents)

        let naiveOutput = smoothing.lines

        for split in 0..<touchEvents.count {
            let left = Array(touchEvents[0..<split])
            let right = Array(touchEvents[split...])

            let altTouchStream = TouchPathStream()
            let altPolylineStream = PolylineStream()
            let altSmoothing = SavitzkyGolay()

            altTouchStream.nextStep(altPolylineStream).nextStep(altSmoothing)
            altTouchStream.produce(with: left)
            altTouchStream.produce(with: right)

            let optimizedOutput = altSmoothing.lines

            XCTAssert(naiveOutput[0] == optimizedOutput[0], "failed in split \(split)")
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
        let savitzkyGolayFilter = SavitzkyGolay()
        let smoother = BezierStream(smoother: AntigrainSmoother())
        touchStream.addConsumer(polylineStream)
        polylineStream.addConsumer(savitzkyGolayFilter)
        savitzkyGolayFilter.addConsumer(smoother)
        touchStream.produce(with: events)

        for split in 1..<events.count {
            let altStream = TouchPathStream()
            let altPolylineStream = PolylineStream()
            let altSavitzkyGolayFilter = SavitzkyGolay()
            let altSmoother = BezierStream(smoother: AntigrainSmoother())
            altStream.addConsumer(altPolylineStream)
            altPolylineStream.addConsumer(altSavitzkyGolayFilter)
            altSavitzkyGolayFilter.addConsumer(altSmoother)
            altStream.produce(with: Array(events[0 ..< split]))
            altStream.produce(with: Array(events[split ..< events.count]))

            XCTAssertEqual(touchStream.paths, altStream.paths)
            XCTAssertEqual(polylineStream.lines, altPolylineStream.lines)
            XCTAssertEqual(savitzkyGolayFilter.lines, altSavitzkyGolayFilter.lines)
            XCTAssertEqual(smoother.paths, altSmoother.paths)
        }
    }
}
