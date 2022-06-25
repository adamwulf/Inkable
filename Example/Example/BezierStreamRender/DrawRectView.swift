//
//  BezierView.swift
//  Inkable
//
//  Created by Adam Wulf on 3/28/21.
//

import UIKit
import Inkable

open class DrawRectView: UIView, Consumer {

    public typealias Consumes = BezierStream.Produces

    override public func layoutSubviews() {
        setNeedsDisplay()
        super.layoutSubviews()
    }

    public func consume(_ input: BezierStream.Produces) {
        // noop
    }

    public func reset() {
        // noop
    }
}
