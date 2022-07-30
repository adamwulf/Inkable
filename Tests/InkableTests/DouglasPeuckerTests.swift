//
//  DouglasPeuckerTests.swift
//
//
//  Created by Adam Wulf on 7/1/22.
//

import XCTest
@testable import Inkable

class DouglasPeuckerTests: XCTestCase {

    func testDouglasPeucker() throws {
        let touchId: UITouchIdentifier = UUID().uuidString
        let completeEvents = [Event(id: touchId, loc: CGPoint(x: -6.19, y: -3.46), pred: false),
                              Event(id: touchId, loc: CGPoint(x: -4.99, y: 1.16), pred: false),
                              Event(id: touchId, loc: CGPoint(x: -2.79, y: -2.22), pred: false),
                              Event(id: touchId, loc: CGPoint(x: -1.87, y: 0.58), pred: false),
                              Event(id: touchId, loc: CGPoint(x: 0.77, y: 0.22), pred: false),
                              Event(id: touchId, loc: CGPoint(x: -1.15, y: 3.06), pred: false),
                              Event(id: touchId, loc: CGPoint(x: 5.33, y: -1.12), pred: false)]
        let touchEvents = TouchEvent.newFrom(completeEvents)
        let touchStream = TouchPathStream()
        let polylineStream = PolylineStream()
        let naive = NaiveDouglasPeucker(epsilon: 5.47722)
        let iterative = IterativeDouglasPeucker(epsilon: 5.47722)

        touchStream.nextStep(polylineStream)
        polylineStream.nextStep(naive)
        polylineStream.nextStep(iterative)
        touchStream.produce(with: touchEvents)

        let expected = Polyline(points: [polylineStream.lines[0].points.first!, polylineStream.lines[0].points.last!])

        XCTAssert(naive.lines[0] == expected)
        XCTAssert(iterative.lines[0] == expected)
    }

    func testDouglasPeucker2() throws {
        let touchId: UITouchIdentifier = UUID().uuidString
        let completeEvents = [Event(id: touchId, loc: CGPoint(x: 0, y: 0), pred: false),
                              Event(id: touchId, loc: CGPoint(x: 50, y: 1), pred: false),
                              Event(id: touchId, loc: CGPoint(x: 100, y: 0), pred: false)]
        let touchEvents = TouchEvent.newFrom(completeEvents)
        let touchStream = TouchPathStream()
        let polylineStream = PolylineStream()
        let naive = NaiveDouglasPeucker(epsilon: 2)
        let iterative = IterativeDouglasPeucker(epsilon: 2)

        touchStream.nextStep(polylineStream)
        polylineStream.nextStep(naive)
        polylineStream.nextStep(iterative)
        touchStream.produce(with: touchEvents)

        XCTAssertEqual(naive.lines[0].description, "[(0.0, 0.0),(100.0, 0.0)]")
        XCTAssertEqual(iterative.lines[0].description, "[(0.0, 0.0),(100.0, 0.0)]")
    }

    func testNaiveDouglasPeucker3() throws {
        let touchId: UITouchIdentifier = UUID().uuidString
        let completeEvents = [Event(id: touchId, loc: CGPoint(x: 0, y: 0), pred: false),
                              Event(id: touchId, loc: CGPoint(x: 50, y: 1), pred: false),
                              Event(id: touchId, loc: CGPoint(x: 100, y: 0), pred: false),
                              Event(id: touchId, loc: CGPoint(x: 101, y: 50), pred: false),
                              Event(id: touchId, loc: CGPoint(x: 100, y: 100), pred: false)]
        let touchEvents = TouchEvent.newFrom(completeEvents)
        let touchStream = TouchPathStream()
        let polylineStream = PolylineStream()
        let naive = NaiveDouglasPeucker(epsilon: 2)
        let iterative = IterativeDouglasPeucker(epsilon: 2)

        touchStream.nextStep(polylineStream)
        polylineStream.nextStep(naive)
        polylineStream.nextStep(iterative)
        touchStream.produce(with: touchEvents)

        XCTAssertEqual(naive.lines[0].description, "[(0.0, 0.0),(100.0, 0.0),(100.0, 100.0)]")
        XCTAssertEqual(iterative.lines[0].description, "[(0.0, 0.0),(100.0, 0.0),(100.0, 100.0)]")
    }

    func testSplitEventSmoothing() throws {
        let touchId: UITouchIdentifier = UUID().uuidString
        let completeEvents = [Event(id: touchId, loc: CGPoint(x: 0, y: 0), pred: false),
                              Event(id: touchId, loc: CGPoint(x: 50, y: 1), pred: false),
                              Event(id: touchId, loc: CGPoint(x: 100, y: 0), pred: false),
                              Event(id: touchId, loc: CGPoint(x: 101, y: 50), pred: false),
                              Event(id: touchId, loc: CGPoint(x: 100, y: 100), pred: false)]
        let touchEvents = TouchEvent.newFrom(completeEvents)
        let touchStream = TouchPathStream()
        let polylineStream = PolylineStream()
        let naive = NaiveDouglasPeucker()
        let iterative = IterativeDouglasPeucker()

        touchStream.nextStep(polylineStream)
        polylineStream.nextStep(naive)
        polylineStream.nextStep(iterative)
        touchStream.produce(with: touchEvents)

        XCTAssert(naive.lines[0] == iterative.lines[0])

        for split in 0..<touchEvents.count {
            let left = Array(touchEvents[0..<split])
            let right = Array(touchEvents[split...])

            let altTouchStream = TouchPathStream()
            let altPolylineStream = PolylineStream()
            let altNaive = NaiveDouglasPeucker()
            let altIterative = IterativeDouglasPeucker()

            altTouchStream.nextStep(altPolylineStream)
            altPolylineStream.nextStep(altNaive)
            altPolylineStream.nextStep(altIterative)
            altTouchStream.produce(with: left)
            altTouchStream.produce(with: right)

            XCTAssert(naive.lines[0] == altNaive.lines[0], "failed in split \(split)")
            XCTAssert(naive.lines[0] == altIterative.lines[0], "failed in split \(split)")
        }
    }

    func testUnknownPolylineIndex() throws {
        guard
            let jsonFile = Bundle.module.url(forResource: "unknown-polyline-index", withExtension: "json")
        else {
            XCTFail("Could not load json")
            return
        }

        for _ in 0..<10 {
            try autoreleasepool {
                let data = try Data(contentsOf: jsonFile)
                let events = try JSONDecoder().decode([TouchEvent].self, from: data)
                let touchStream = TouchPathStream()
                let polylineStream = PolylineStream()
                let naiveFilter = NaiveDouglasPeucker()
                let iterativeFilter = NaiveDouglasPeucker()
                touchStream.addConsumer(polylineStream)
                polylineStream.addConsumer(naiveFilter)
                polylineStream.addConsumer(iterativeFilter)
                touchStream.produce(with: events)

                XCTAssertEqual(naiveFilter.lines, iterativeFilter.lines)

                for split in 1..<events.count {
                    let altStream = TouchPathStream()
                    let altPolylineStream = PolylineStream()
                    let altNaiveFilter = NaiveDouglasPeucker()
                    let altIterativeFilter = IterativeDouglasPeucker()
                    altStream.addConsumer(altPolylineStream)
                    altPolylineStream.addConsumer(altNaiveFilter)
                    altPolylineStream.addConsumer(altIterativeFilter)
                    altStream.produce(with: Array(events[0 ..< split]))
                    altStream.produce(with: Array(events[split ..< events.count]))

                    XCTAssertEqual(touchStream.paths, altStream.paths)
                    XCTAssertEqual(polylineStream.lines, altPolylineStream.lines)
                    XCTAssertEqual(naiveFilter.lines, altNaiveFilter.lines)
                    XCTAssertEqual(naiveFilter.lines, altIterativeFilter.lines)
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
