//
//  Smoother.swift
//  Inkable
//
//  Created by Adam Wulf on 3/19/21.
//

import UIKit

/// A protocol that defines methods for smoothing and manipulating polylines into Bézier curves.
public protocol Smoother {
    /// Generates a Bézier element for a specific point in the polyline.
    ///
    /// - Parameters:
    ///   - line: The polyline to generate the element from.
    ///   - elementIndex: The index of the Bézier element to generate from the polyline.
    /// - Returns: A `BezierElementStream.Element` representing the smoothed Bézier element.
    func element(for line: Polyline, at elementIndex: Int) -> BezierElementStream.Element

    /// Determines the maximum index of elements that can be generated from the given polyline.
    ///
    /// - Parameter line: The polyline to analyze.
    /// - Returns: The maximum index of Bézier elements that can be generated from the polyline.
    func maxIndex(for line: Polyline) -> Int

    /// Calculates the range of element indexes that correspond to a range of line indexes.
    ///
    /// - Parameters:
    ///   - line: The polyline to analyze.
    ///   - lineIndexes: The range of line indexes to convert.
    ///   - bezier: The Bézier curve context for the calculation. If this input Bézier is longer than can be built with the input line, then the extra element indexes will be returned.
    /// - Returns: A `MinMaxIndex` representing the range of Bézier element indexes.
    func elementIndexes(for line: Polyline, at lineIndexes: MinMaxIndex, with bezier: BezierElementStream.Bezier) -> MinMaxIndex

    /// Calculates the range of element indexes that correspond to a single line index.
    ///
    /// - Parameters:
    ///   - line: The polyline to analyze.
    ///   - lineIndex: The specific line index to convert.
    ///   - bezier: The Bézier curve context for the calculation. If this input Bézier is longer than can be built with the input line, then the extra element indexes will be returned.
    /// - Returns: A `MinMaxIndex` representing the range of Bézier element indexes.
    func elementIndexes(for line: Polyline, at lineIndex: Int, with bezier: BezierElementStream.Bezier) -> MinMaxIndex
}
