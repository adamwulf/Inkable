//
//  DouglasPeuckerTests.swift
//
//
//  Created by Adam Wulf on 7/1/22.
//

import XCTest
@testable import Inkable

class DouglasPeuckerTests: XCTestCase {

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
        let smoothing = NaiveDouglasPeucker()

        touchStream.nextStep(polylineStream).nextStep(smoothing)
        touchStream.produce(with: touchEvents)

        let naiveOutput = smoothing.lines

        for split in 0..<touchEvents.count {
            let left = Array(touchEvents[0..<split])
            let right = Array(touchEvents[split...])

            let altTouchStream = TouchPathStream()
            let altPolylineStream = PolylineStream()
            let altSmoothing = NaiveDouglasPeucker()

            altTouchStream.nextStep(altPolylineStream).nextStep(altSmoothing)
            altTouchStream.produce(with: left)
            altTouchStream.produce(with: right)

            let optimizedOutput = altSmoothing.lines

            XCTAssert(naiveOutput[0] == optimizedOutput[0], "failed in split \(split)")
        }
    }

    func testUnknownPolylineIndex() throws {
        for _ in 0..<10 {
            try autoreleasepool {
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
                let douglasPeuckerFilter = NaiveDouglasPeucker()
                let smoother = BezierStream(smoother: AntigrainSmoother())
                touchStream.addConsumer(polylineStream)
                polylineStream.addConsumer(douglasPeuckerFilter)
                douglasPeuckerFilter.addConsumer(smoother)
                touchStream.produce(with: events)

                for split in 1..<events.count {
                    let altStream = TouchPathStream()
                    let altPolylineStream = PolylineStream()
                    let altDouglasPeuckerFilter = NaiveDouglasPeucker()
                    let altSmoother = BezierStream(smoother: AntigrainSmoother())
                    altStream.addConsumer(altPolylineStream)
                    altPolylineStream.addConsumer(altDouglasPeuckerFilter)
                    altDouglasPeuckerFilter.addConsumer(altSmoother)
                    altStream.produce(with: Array(events[0 ..< split]))
                    altStream.produce(with: Array(events[split ..< events.count]))

                    XCTAssertEqual(touchStream.paths, altStream.paths)
                    XCTAssertEqual(polylineStream.lines, altPolylineStream.lines)
                    XCTAssertEqual(douglasPeuckerFilter.lines, altDouglasPeuckerFilter.lines)
                    XCTAssertEqual(smoother.paths, altSmoother.paths)
                }
            }
        }
    }

    func testCoeffs() {
        let order = 3
        let deriv = 0

        // window = 2
        var coeffs = Coeffs(index: 0, windowSize: 2)
        XCTAssertEqual(coeffs.weight(-2, order, deriv), -0.08571428571428569)
        XCTAssertEqual(coeffs.weight(-1, order, deriv), 0.34285714285714286)
        XCTAssertEqual(coeffs.weight(0, order, deriv), 0.4857142857142857)
        XCTAssertEqual(coeffs.weight(1, order, deriv), 0.34285714285714286)
        XCTAssertEqual(coeffs.weight(2, order, deriv), -0.08571428571428569)

        // window = 3
        coeffs = Coeffs(index: 0, windowSize: 3)
        XCTAssertEqual(coeffs.weight(-3, order, deriv), -0.0952380952380952)
        XCTAssertEqual(coeffs.weight(-2, order, deriv), 0.14285714285714288)
        XCTAssertEqual(coeffs.weight(-1, order, deriv), 0.2857142857142857)
        XCTAssertEqual(coeffs.weight(0, order, deriv), 0.33333333333333337)
        XCTAssertEqual(coeffs.weight(1, order, deriv), 0.2857142857142857)
        XCTAssertEqual(coeffs.weight(2, order, deriv), 0.14285714285714288)
        XCTAssertEqual(coeffs.weight(3, order, deriv), -0.0952380952380952)

        // window = 4
        coeffs = Coeffs(index: 0, windowSize: 4)
        XCTAssertEqual(coeffs.weight(-4, order, deriv), -0.09090909090909091)
        XCTAssertEqual(coeffs.weight(-3, order, deriv), 0.060606060606060615)
        XCTAssertEqual(coeffs.weight(-2, order, deriv), 0.16883116883116883)
        XCTAssertEqual(coeffs.weight(-1, order, deriv), 0.2337662337662338)
        XCTAssertEqual(coeffs.weight(0, order, deriv), 0.2554112554112554)
        XCTAssertEqual(coeffs.weight(1, order, deriv), 0.2337662337662338)
        XCTAssertEqual(coeffs.weight(2, order, deriv), 0.16883116883116883)
        XCTAssertEqual(coeffs.weight(3, order, deriv), 0.060606060606060615)
        XCTAssertEqual(coeffs.weight(4, order, deriv), -0.09090909090909091)

        // window = 12
        coeffs = Coeffs(index: 0, windowSize: 12)
        XCTAssertEqual(coeffs.weight(-12, order, deriv), -0.04888888888888888)
        XCTAssertEqual(coeffs.weight(-11, order, deriv), -0.026666666666666665)
        XCTAssertEqual(coeffs.weight(-10, order, deriv), -0.0063768115942028775)
        XCTAssertEqual(coeffs.weight(-9, order, deriv), 0.011980676328502408)
        XCTAssertEqual(coeffs.weight(-8, order, deriv), 0.028405797101449276)
        XCTAssertEqual(coeffs.weight(-7, order, deriv), 0.042898550724637684)
        XCTAssertEqual(coeffs.weight(-6, order, deriv), 0.05545893719806763)
        XCTAssertEqual(coeffs.weight(-5, order, deriv), 0.06608695652173913)
        XCTAssertEqual(coeffs.weight(-4, order, deriv), 0.07478260869565218)
        XCTAssertEqual(coeffs.weight(-3, order, deriv), 0.08154589371980676)
        XCTAssertEqual(coeffs.weight(-2, order, deriv), 0.0863768115942029)
        XCTAssertEqual(coeffs.weight(-1, order, deriv), 0.08927536231884058)
        XCTAssertEqual(coeffs.weight(0, order, deriv), 0.0902415458937198)
        XCTAssertEqual(coeffs.weight(1, order, deriv), 0.08927536231884058)
        XCTAssertEqual(coeffs.weight(2, order, deriv), 0.0863768115942029)
        XCTAssertEqual(coeffs.weight(3, order, deriv), 0.08154589371980676)
        XCTAssertEqual(coeffs.weight(4, order, deriv), 0.07478260869565218)
        XCTAssertEqual(coeffs.weight(5, order, deriv), 0.06608695652173913)
        XCTAssertEqual(coeffs.weight(6, order, deriv), 0.05545893719806763)
        XCTAssertEqual(coeffs.weight(7, order, deriv), 0.042898550724637684)
        XCTAssertEqual(coeffs.weight(8, order, deriv), 0.028405797101449276)
        XCTAssertEqual(coeffs.weight(9, order, deriv), 0.011980676328502408)
        XCTAssertEqual(coeffs.weight(10, order, deriv), -0.0063768115942028775)
        XCTAssertEqual(coeffs.weight(11, order, deriv), -0.026666666666666665)
        XCTAssertEqual(coeffs.weight(12, order, deriv), -0.04888888888888888)
    }
}
