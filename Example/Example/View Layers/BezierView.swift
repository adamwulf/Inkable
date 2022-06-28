//
//  BezierView.swift
//  Example
//
//  Created by Adam Wulf on 6/25/22.
//

import Foundation
import UIKit
import Inkable

class BezierView: UIView, Consumer {

    typealias Consumes = BezierStream.Produces

    private static let lineWidth: CGFloat = 1

    var renderTransform: CGAffineTransform = .identity {
        didSet {
            setNeedsDisplay()
        }
    }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .clear
        isOpaque = false
        isUserInteractionEnabled = false
    }

    override var isHidden: Bool {
        didSet {
            setNeedsDisplay()
        }
    }

    // MARK: - TouchPathStream Consumer

    private(set) var model: Consumes = Consumes(paths: [], deltas: [])

    func consume(_ input: BezierStream.Produces) {
        let previousModel = model
        model = input

        for delta in input.deltas {
            switch delta {
            case .addedBezierPath(let index):
                let path = model.paths[index]
                setNeedsDisplay(path.bounds.expand(by: Self.lineWidth).applying(renderTransform))
            case .updatedBezierPath(let index, _):
                // We could only setNeedsDisplay for the rect of the modified elements of the path.
                // For now, we'll set the entire path as needing display, but something to possibly revisit
                let path = model.paths[index]
                setNeedsDisplay(path.bounds.expand(by: Self.lineWidth).applying(renderTransform))
                if index < previousModel.paths.count {
                    let previous = previousModel.paths[index]
                    setNeedsDisplay(previous.bounds.expand(by: Self.lineWidth).applying(renderTransform))
                }
            case .completedBezierPath(let index):
                let path = model.paths[index]
                setNeedsDisplay(path.bounds.expand(by: Self.lineWidth).applying(renderTransform))
            case .unhandled(let event):
                print("Unhandled event: \(event.identifier)")
            }
        }
    }

    func reset() {
        model = Consumes(paths: [], deltas: [])
        setNeedsDisplay()
    }

    // MARK: - Draw

    override func draw(_ rect: CGRect) {
        guard !isHidden else { return }

        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        context?.concatenate(renderTransform)

        for path in model.paths {
            let path = path.copy() as! UIBezierPath
            path.lineWidth = Self.lineWidth

            UIColor.green.setStroke()

            path.stroke()
        }

        context?.restoreGState()
    }
}
