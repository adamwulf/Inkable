//
//  ClippedBezierStreamTests.swift
//  InkableTests
//
//  Created by Adam Wulf on 5/1/21.
//

import XCTest
@testable import Inkable

class ClippedBezierStreamTests: XCTestCase {
    static let pen = AttributesStream.ToolStyle(width: 1.5, color: .black)
    static let eraser = AttributesStream.ToolStyle(width: 10, color: nil)

    lazy var attributeStream = { () -> AttributesStream in
        let attributeStream = AttributesStream()
        return attributeStream
    }()

    override func setUp() {
        attributeStream.reset()
        attributeStream.styleOverride = { delta in
            switch delta {
            case .addedBezierPath(let index):
                return index == 0 ? Self.pen : Self.eraser
            default:
                return nil
            }
        }
    }

    func testClippedLines() throws {
        var simpleEvents = Event.events(from: CGPoint(x: 100, y: 100), to: CGPoint(x: 200, y: 100)) +
            Event.events(from: CGPoint(x: 150, y: 50), to: CGPoint(x: 150, y: 150))
        var touchEvents = TouchEvent.newFrom(simpleEvents)

        let touchPathStream = TouchPathStream()
        let polylineStream = PolylineStream()
        let bezierStream = BezierStream(smoother: AntigrainSmoother())
        let clippedStream = ClippedBezierStream()

        var touchPathOutput = touchPathStream.produce(with: touchEvents)
        var polylineOutput = polylineStream.produce(with: touchPathOutput)
        var bezierOutput = bezierStream.produce(with: polylineOutput)
        var attributedOutput = attributeStream.produce(with: bezierOutput)
        var clippedOutput = clippedStream.produce(with: attributedOutput)

        XCTAssertEqual(clippedOutput.paths.count, 4)
        XCTAssertEqual(clippedOutput.deltas.count, 5)

        XCTAssertEqual(clippedOutput.deltas[0], .addedBezierPath(index: 0))
        XCTAssertEqual(clippedOutput.deltas[1], .completedBezierPath(index: 0))
        XCTAssertEqual(clippedOutput.deltas[2], .addedBezierPath(index: 1))
        XCTAssertEqual(clippedOutput.deltas[3], .replacedBezierPath(index: 0, withPathIndexes: IndexSet(2..<4)))
        XCTAssertEqual(clippedOutput.deltas[4], .invalidatedBezierPath(index: 1))

        simpleEvents = Event.events(from: CGPoint(x: 175, y: 50), to: CGPoint(x: 175, y: 150))
        touchEvents = TouchEvent.newFrom(simpleEvents)

        touchPathOutput = touchPathStream.produce(with: touchEvents)
        polylineOutput = polylineStream.produce(with: touchPathOutput)
        bezierOutput = bezierStream.produce(with: polylineOutput)
        attributedOutput = attributeStream.produce(with: bezierOutput)
        clippedOutput = clippedStream.produce(with: attributedOutput)

        XCTAssertEqual(clippedOutput.paths.count, 7)
        XCTAssertEqual(clippedOutput.deltas.count, 3)

        XCTAssertEqual(clippedOutput.deltas[0], .addedBezierPath(index: 4))
        XCTAssertEqual(clippedOutput.deltas[1], .replacedBezierPath(index: 3, withPathIndexes: IndexSet(5..<7)))
        XCTAssertEqual(clippedOutput.deltas[2], .invalidatedBezierPath(index: 4))
    }

    func testClippTwoLines() throws {
        let simpleEvents = Event.events(from: CGPoint(x: 100, y: 100), to: CGPoint(x: 200, y: 100)) +
            Event.events(from: CGPoint(x: 100, y: 200), to: CGPoint(x: 200, y: 200)) +
            Event.events(from: CGPoint(x: 150, y: 50), to: CGPoint(x: 150, y: 250))
        let touchEvents = TouchEvent.newFrom(simpleEvents)

        attributeStream.styleOverride = { delta in
            switch delta {
            case .addedBezierPath(let index):
                return index < 2 ? Self.pen : Self.eraser
            default:
                return nil
            }
        }

        let touchPathStream = TouchPathStream()
        let polylineStream = PolylineStream()
        let bezierStream = BezierStream(smoother: AntigrainSmoother())
        let clippedStream = ClippedBezierStream()

        let touchPathOutput = touchPathStream.produce(with: touchEvents)
        let polylineOutput = polylineStream.produce(with: touchPathOutput)
        let bezierOutput = bezierStream.produce(with: polylineOutput)
        let attributedOutput = attributeStream.produce(with: bezierOutput)
        let clippedOutput = clippedStream.produce(with: attributedOutput)

        XCTAssertEqual(clippedOutput.paths.count, 7)
        XCTAssertEqual(clippedOutput.deltas.count, 8)

        XCTAssertEqual(clippedOutput.deltas[0], .addedBezierPath(index: 0))
        XCTAssertEqual(clippedOutput.deltas[1], .completedBezierPath(index: 0))
        XCTAssertEqual(clippedOutput.deltas[2], .addedBezierPath(index: 1))
        XCTAssertEqual(clippedOutput.deltas[3], .completedBezierPath(index: 1))
        XCTAssertEqual(clippedOutput.deltas[4], .addedBezierPath(index: 2))
        XCTAssertEqual(clippedOutput.deltas[5], .replacedBezierPath(index: 0, withPathIndexes: IndexSet(3..<5)))
        XCTAssertEqual(clippedOutput.deltas[6], .replacedBezierPath(index: 1, withPathIndexes: IndexSet(5..<7)))
        XCTAssertEqual(clippedOutput.deltas[7], .invalidatedBezierPath(index: 2))
    }
}
