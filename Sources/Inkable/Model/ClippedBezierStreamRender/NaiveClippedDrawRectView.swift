//
//  NaiveClippedDrawRectView.swift
//  Inkable
//
//  Created by Adam Wulf on 4/4/21.
//

import UIKit
import MMSwiftToolbox
import PerformanceBezier

public class NaiveClippedDrawRectView: ClippedBezierView {

    private var model: ClippedBezierStream.Produces = ClippedBezierStream.Produces.empty

    override public func consume(_ input: Consumes) {
        model = input

        if !input.deltas.isEmpty {
            setNeedsDisplay()
        }
    }

    override public func reset() {
        model = ClippedBezierStream.Produces.empty
        setNeedsDisplay()
    }

    override public func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }

        model.draw(at: rect, in: context)
    }
}
