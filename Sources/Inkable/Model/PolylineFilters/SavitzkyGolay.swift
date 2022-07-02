//
//  SavitzkyGolay.swift
//  Inkable
//
//  Created by Adam Wulf on 8/18/20.
//

import UIKit
import SwiftToolbox

/// Smooths the points of the input strokes using the Savitzky–Golay filter, which smooths a stroke by fitting a polynomial, in a least squares sense, to a sliding window of its points.
/// https://en.wikipedia.org/wiki/Savitzky%E2%80%93Golay_filter
/// Coefficients are calculated with the algorithm from https://dekalogblog.blogspot.com/2013/09/savitzky-golay-filter-convolution.html
/// Values were confirmed against the coefficients listed at http://www.statistics4u.info/fundstat_eng/cc_savgol_coeff.html
open class SavitzkyGolay: ProducerConsumer {

    public typealias Consumes = PolylineStream.Produces
    public typealias Produces = PolylineStream.Produces

    // MARK: - Private

    private let coeffs = Coeffs(index: 0)
    private let deriv: Int // 0 is smooth, 1 is first derivative, etc
    private let order: Int
    private var consumers: [(process: (Produces) -> Void, reset: () -> Void)] = []

    // MARK: Public

    public private(set) var lines: [Polyline] = []

    public var enabled: Bool = true
    @Clamped(2...12) public var window: Int = 2
    @Clamped(0...1) public var strength: CGFloat = 1

    // MARK: Init

    public init () {
        strength = 1
        deriv = 0
        order = 3
    }

    // MARK: - ProducerConsumer<Polyline>

    public func reset() {
        consumers.forEach({ $0.reset() })
        lines = []
    }

    // MARK: - Producer<Polyline>

    public func addConsumer<Customer>(_ consumer: Customer) where Customer: Consumer, Customer.Consumes == Produces {
        consumers.append((process: { (produces: Produces) in
            consumer.consume(produces)
        }, reset: consumer.reset))
    }

    public func addConsumer(_ block: @escaping (Produces) -> Void) {
        consumers.append((process: block, reset: {}))
    }

    // MARK: - Consumer<Polyline>

    @discardableResult
    public func produce(with input: Consumes) -> Produces {
        guard enabled else {
            consumers.forEach({ $0.process(input) })
            return input
        }
        var outDeltas: [PolylineStream.Delta] = []
        for delta in input.deltas {
            switch delta {
            case .addedPolyline(let strokeIndex):
                assert(strokeIndex == lines.count)
                let line = input.lines[strokeIndex]
                lines.append(line)
                let indexes = IndexSet(integersIn: 0..<line.points.count)
                smoothStroke(stroke: &lines[strokeIndex], at: indexes, input: line)
                outDeltas.append(delta)
            case .completedPolyline(let strokeIndex):
                lines[strokeIndex].isComplete = true
                outDeltas.append(delta)
            case .updatedPolyline(let strokeIndex, let indexes):
                let line = input.lines[strokeIndex]
                let updatedIndexes = smoothStroke(stroke: &lines[strokeIndex], at: indexes, input: line)
                outDeltas.append(.updatedPolyline(index: strokeIndex, updatedIndexes: updatedIndexes))
            default:
                outDeltas.append(delta)
            }
        }

        let output = Produces(lines: lines, deltas: outDeltas)
        self.lines = output.lines
        consumers.forEach({ $0.process(output) })
        return output
    }

    // MARK: - Private

    @discardableResult
    private func smoothStroke(stroke: inout Polyline, at indexes: IndexSet?, input: Polyline) -> IndexSet {
        if input.points.count > stroke.points.count {
            stroke.points.append(contentsOf: input.points[stroke.points.count...])
        } else if input.points.count < stroke.points.count {
            stroke.points.removeSubrange(input.points.count...)
        }
        let outIndexes = { () -> IndexSet in
            if let indexes = indexes,
               let minIndex = indexes.min(),
               let maxIndex = indexes.max() {
                var outIndexes = IndexSet()
                let start = max(0, minIndex - window)
                let end = min(stroke.points.count - 1, maxIndex + window)
                outIndexes.insert(integersIn: start...end)
                return outIndexes
            }
            return IndexSet(stroke.points.indices)
        }()

        for pIndex in outIndexes {
            let minWin = min(min(window, pIndex), stroke.points.count - 1 - pIndex)
            // copy over the point in question so that not only our location will be smoothed below,
            // but also the azimuth/altitude/etc will be the same
            stroke.points[pIndex] = input.points[pIndex]
            if minWin > 1 {
                var outPoint = CGPoint.zero
                for windowPos in -minWin ... minWin {
                    let wght = coeffs.weight(windowPos, minWin, order, deriv)
                    outPoint.x += wght * input.points[pIndex + windowPos].location.x
                    outPoint.y += wght * input.points[pIndex + windowPos].location.y
                }
                let origPoint = stroke.points[pIndex].location

                stroke.points[pIndex].location = origPoint * CGFloat(1 - strength) + outPoint * strength
            }
        }

        return outIndexes
    }

}

class Coeffs {

    private let index: Int
    private var cache: [Int: [CGFloat]] = [:]

    init(index: Int) {
        self.index = index
    }

    func weight(_ windowLoc: Int, _ windowSize: Int, _ order: Int, _ derivative: Int) -> CGFloat {
        guard abs(windowLoc) <= windowSize else { fatalError("Invalid coefficient") }
        if let cached = cache[windowSize] {
            return cached[abs(windowLoc)]
        }
        var coeffs: [CGFloat] = []
        for windowLoc in 0...windowSize {
            coeffs.append(Self.calcWeight(index, windowLoc, windowSize, order, derivative))
        }

        cache[windowSize] = coeffs

        return coeffs[abs(windowLoc)]
    }

    // MARK: - Coefficients

    /// calculates the generalised factorial (a)(a-1)...(a-b+1)
    private static func genFact(_ a: Int, _ b: Int) -> CGFloat {
        var gf: CGFloat = 1.0

        for jj in (a - b + 1) ..< (a + 1) {
            gf *= CGFloat(jj)
        }
        return gf
    }

    /// Calculates the Gram Polynomial ( s = 0 ), or its s'th
    /// derivative evaluated at i, order k, over 2m + 1 points
    private static func gramPoly(_ index: Int, _ window: Int, _ order: Int, _ derivative: Int) -> CGFloat {
        var gp_val: CGFloat

        if order > 0 {
            let g1 = gramPoly(index, window, order - 1, derivative)
            let g2 = gramPoly(index, window, order - 1, derivative - 1)
            let g3 = gramPoly(index, window, order - 2, derivative)
            let i: CGFloat = CGFloat(index)
            let m: CGFloat = CGFloat(window)
            let k: CGFloat = CGFloat(order)
            let s: CGFloat = CGFloat(derivative)
            gp_val = (4.0 * k - 2.0) / (k * (2.0 * m - k + 1.0)) * (i * g1 + s * g2)
                - ((k - 1.0) * (2.0 * m + k)) / (k * (2.0 * m - k + 1.0)) * g3
        } else if order == 0 && derivative == 0 {
            gp_val = 1.0
        } else {
            gp_val = 0.0
        }
        return gp_val
    }

    /// calculates the weight of the i'th data point for the t'th Least-square
    /// point of the s'th derivative, over 2m + 1 points, order n
    private static func calcWeight(_ index: Int, _ windowLoc: Int, _ windowSize: Int, _ order: Int, _ derivative: Int) -> CGFloat {
        var sum: CGFloat = 0.0

        for k in 0 ..< order + 1 {
            sum += CGFloat(2 * k + 1) * CGFloat(genFact(2 * windowSize, k) / genFact(2 * windowSize + k + 1, k + 1))
                * gramPoly(index, windowSize, k, 0) * gramPoly(windowLoc, windowSize, k, derivative)
        }

        return sum
    }

    static func testCoeff(deriv: Int) {
        for m in 2...12 {
            // for a window of 2*m+1 points ( from p[-m] => p[m],
            // the coefficents for p[0]...p[m] or p[0]...p[-m] are given
            // for a cubic curve
            print("\(m)")
            for windowPos in -m ... m {
                let term = 0 // coefficients to adjust p[0] when looking at p[-m] ... p[m]
                let order = 3 // cubic curve
                print("  \(windowPos): \(calcWeight(term, windowPos, m, order, deriv))")
            }
        }
    }
}
