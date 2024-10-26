//
//  Smoother.swift
//  Inkable
//
//  Created by Adam Wulf on 3/19/21.
//

import UIKit

public protocol Smoother {
    func element(for line: Polyline, at elementIndex: Int) -> BezierElementStream.Element
    func maxIndex(for line: Polyline) -> Int
    func elementIndexes(for line: Polyline, at lineIndexes: MinMaxIndex, with bezier: UIBezierPath) -> MinMaxIndex
    func elementIndexes(for line: Polyline, at lineIndex: Int, with bezier: UIBezierPath) -> MinMaxIndex
}
