//
//  PointsView.swift
//  Example
//
//  Created by Adam Wulf on 6/25/22.
//

import Foundation
import UIKit
import Inkable

class PointsView: UIView, Consumer {

    typealias Consumes = PolylineStream.Produces

    private static let maxRadius: CGFloat = 2

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

    private var pathBounds: [String: CGRect] = [:]
    private var model: Consumes = Consumes(lines: [], deltas: [])

    func setNeedsDisplay(in path: Polyline) {
        if let oldBounds = pathBounds[path.touchIdentifier] {
            setNeedsDisplay(oldBounds.expand(by: Self.maxRadius).applying(renderTransform))
        }
        pathBounds[path.touchIdentifier] = path.bounds
        setNeedsDisplay(path.bounds.expand(by: Self.maxRadius).applying(renderTransform))
    }

    func consume(_ input: PolylineStream.Produces) {
        model = input

        for delta in input.deltas {
            switch delta {
            case .addedPolyline(let index):
                let path = model.lines[index]
                setNeedsDisplay(in: path)
            case .updatedPolyline(let index, _):
                // We could only setNeedsDisplay for the rect of the modified elements of the path.
                // For now, we'll set the entire path as needing display, but something to possibly revisit
                let path = model.lines[index]
                setNeedsDisplay(in: path)
            case .completedPolyline(let index):
                let path = model.lines[index]
                setNeedsDisplay(in: path)
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

        for path in model.lines {
            for point in path.points {
                var radius: CGFloat = Self.maxRadius / scale
                if point.event.isUpdate {
                    radius = Self.maxRadius * 3 / 4 / scale
                    if !point.expectsUpdate {
                        UIColor.isFinal.setFill()
                    } else {
                        UIColor.isUpdate.setFill()
                    }
                } else if point.event.isPrediction {
                    UIColor.isPrediction.setFill()
                } else {
                    if !point.event.expectsUpdate {
                        UIColor.isFinal.setFill()
                    } else {
                        UIColor.isIntial.setFill()
                    }
                }
                UIBezierPath(ovalIn: CGRect(origin: point.location, size: CGSize.zero).expand(by: radius)).fill()
            }
        }

        context?.restoreGState()
    }
}
