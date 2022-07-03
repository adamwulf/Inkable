//
//  PolylineView.swift
//  Example
//
//  Created by Adam Wulf on 6/25/22.
//

import Foundation
import UIKit
import Inkable

class PolylineView: UIView, Consumer {

    typealias Consumes = PolylineStream.Produces

    private static let lineWidth: CGFloat = 1
    private let color: UIColor

    var renderTransform: CGAffineTransform = .identity {
        didSet {
            setNeedsDisplay()
        }
    }

    // MARK: - Init

    init(frame: CGRect, color: UIColor = .red) {
        self.color = color
        super.init(frame: frame)
        backgroundColor = .clear
        isOpaque = false
        isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        self.color = .red
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

    private var model: Consumes = Consumes(lines: [], deltas: [])

    func consume(_ input: PolylineStream.Produces) {
        let previousModel = model
        model = input

        for delta in input.deltas {
            switch delta {
            case .addedPolyline(let index):
                let path = model.lines[index]
                setNeedsDisplay(path.bounds.expand(by: Self.lineWidth).applying(renderTransform))
            case .updatedPolyline(let index, _):
                // We could only setNeedsDisplay for the rect of the modified elements of the path.
                // For now, we'll set the entire path as needing display, but something to possibly revisit
                let path = model.lines[index]
                setNeedsDisplay(path.bounds.expand(by: Self.lineWidth).applying(renderTransform))
                if index < previousModel.lines.count {
                    let previous = previousModel.lines[index]
                    setNeedsDisplay(previous.bounds.expand(by: Self.lineWidth).applying(renderTransform))
                }
            case .completedPolyline(let index):
                let path = model.lines[index]
                setNeedsDisplay(path.bounds.expand(by: Self.lineWidth).applying(renderTransform))
            case .unhandled(let event):
                if event as? GestureCallbackEvent != nil {
                    break
                }
                print("Unhandled event: \(event.identifier)")
            }
        }
    }

    func reset() {
        model = Consumes(lines: [], deltas: [])
        setNeedsDisplay()
    }

    // MARK: - Draw

    override func draw(_ rect: CGRect) {
        guard !isHidden else { return }

        let scale = max(renderTransform.a, renderTransform.d)
        let context = UIGraphicsGetCurrentContext()
        context?.saveGState()
        context?.concatenate(renderTransform)

        for polyline in model.lines {
            color.setStroke()

            let path = UIBezierPath()
            path.lineWidth = Self.lineWidth / scale
            for point in polyline.points {
                if point.event.phase == .began {
                    path.move(to: point.location)
                } else {
                    path.addLine(to: point.location)
                }
            }
            path.stroke()
        }
        context?.restoreGState()
    }
}
