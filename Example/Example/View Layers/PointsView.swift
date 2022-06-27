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

    private var model: Consumes = Consumes(paths: [], deltas: [])

    func consume(_ input: TouchPathStream.Produces) {
        let previousModel = model
        model = input

        for delta in input.deltas {
            switch delta {
            case .addedTouchPath(let index):
                let path = model.paths[index]
                setNeedsDisplay(path.bounds)
            case .updatedTouchPath(let index, _):
                // We could only setNeedsDisplay for the rect of the modified elements of the path.
                // For now, we'll set the entire path as needing display, but something to possibly revisit
                let path = model.paths[index]
                setNeedsDisplay(path.bounds)
                if index < previousModel.paths.count {
                    let previous = previousModel.paths[index]
                    setNeedsDisplay(previous.bounds)
                }
            case .completedTouchPath(let index):
                let path = model.paths[index]
                setNeedsDisplay(path.bounds)
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

        for path in model.paths {
            for point in path.points {
                var radius: CGFloat = 2
                if point.event.isUpdate {
                    radius = 1
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
                        UIColor.isUpdate.setFill()
                    }
                }
                UIBezierPath(ovalIn: CGRect(origin: point.event.location, size: CGSize.zero).expand(by: radius)).fill()
            }
        }
    }
}
