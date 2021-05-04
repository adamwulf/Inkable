//
//  ClippedBezierView.swift
//  Inkable
//
//  Created by Adam Wulf on 4/4/21.
//

import UIKit

public class ClippedBezierView: UIView, Consumer {

    public typealias Consumes = ClippedBezierStream.Produces

    override public func layoutSubviews() {
        setNeedsDisplay()
        super.layoutSubviews()
    }

    public func consume(_ input: ClippedBezierStream.Produces) {
        // noop
    }

    public func reset() {
        // noop
    }
}
