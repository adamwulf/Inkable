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

    typealias Consumes = TouchPathStream.Produces

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
    private var model: Consumes = Consumes(paths: [], deltas: [])

    func setNeedsDisplay(in path: TouchPath) {
        if let oldBounds = pathBounds[path.touchIdentifier] {
            setNeedsDisplay(oldBounds.expand(by: Self.maxRadius).applying(renderTransform))
        }
        pathBounds[path.touchIdentifier] = path.bounds
        setNeedsDisplay(path.bounds.expand(by: Self.maxRadius).applying(renderTransform))
    }

    func consume(_ input: TouchPathStream.Produces) {
        model = input

        for delta in input.deltas {
            switch delta {
            case .addedTouchPath(let index):
                let path = model.paths[index]
                setNeedsDisplay(in: path)
            case .updatedTouchPath(let index, _):
                // We could only setNeedsDisplay for the rect of the modified elements of the path.
                // For now, we'll set the entire path as needing display, but something to possibly revisit
                let path = model.paths[index]
                setNeedsDisplay(in: path)
            case .completedTouchPath(let index):
                let path = model.paths[index]
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
            for point in path.points {
                var radius: CGFloat = Self.maxRadius
                if point.event.isUpdate {
                    radius = Self.maxRadius / 2
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
                UIBezierPath(ovalIn: CGRect(origin: point.event.location, size: CGSize.zero).expand(by: radius)).fill()
            }
        }

        context?.restoreGState()
    }
}
