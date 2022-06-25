//
//  NaiveDrawRectView.swift
//  Inkable
//
//  Created by Adam Wulf on 3/15/21.
//

import UIKit
import Inkable
import SwiftToolbox
import PerformanceBezier

open class NaiveDrawRectView: BezierView {

    private var model: BezierStream.Produces = BezierStream.Produces.empty

    override public func consume(_ input: Consumes) {
        model = input

        if !input.deltas.isEmpty {
            setNeedsDisplay()
        }
    }

    override public func reset() {
        model = BezierStream.Produces.empty
        setNeedsDisplay()
    }

    override public func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        model.draw(at: rect, in: context)
    }
}
