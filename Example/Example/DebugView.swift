//
//  DebugView.swift
//  DrawUIExample
//
//  Created by Adam Wulf on 8/16/20.
//

import UIKit
import Inkable

class DebugView: UIView {
    var originalStrokes: [Polyline] = []
    var smoothStrokes: [UIBezierPath] = []
    private var deltas: [PolylineStream.Delta]?

    override public func layoutSubviews() {
        setNeedsDisplay()
        super.layoutSubviews()
    }

    func add(deltas: [PolylineStream.Delta]) {
        if self.deltas == nil {
            self.deltas = []
        }
        self.deltas?.append(contentsOf: deltas)
    }

    func reset() {
        originalStrokes = []
        smoothStrokes = []
        deltas = []
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        for stroke in originalStrokes {
            for event in stroke.points.flatMap({ $0.touchPoint.events }) {
                var radius: CGFloat = 2
                if event.isUpdate {
                    radius = 1
                    if !event.expectsUpdate {
                        UIColor.red.setFill()
                    } else {
                        UIColor.green.setFill()
                    }
                } else if event.isPrediction {
                    UIColor.blue.setFill()
                } else {
                    if !event.expectsUpdate {
                        UIColor.red.setFill()
                    } else {
                        UIColor.green.setFill()
                    }
                }
                UIBezierPath(ovalIn: CGRect(origin: event.location, size: CGSize.zero).expand(by: radius)).fill()
            }

            UIColor.red.setStroke()

            let path = UIBezierPath()
            for point in stroke.points {
                if point.event.phase == .began {
                    path.move(to: point.location)
                } else {
                    path.addLine(to: point.location)
                }
            }
            path.stroke()
        }

        for path in smoothStrokes {
            UIColor.green.setStroke()

            path.stroke()
        }

        if let deltas = deltas {
            func draw(stroke: Polyline, indexSet: IndexSet?) {
                UIColor.red.setStroke()
                if let indexSet = indexSet {
                    for index in indexSet {
                        if index < stroke.points.count {
                            let point = stroke.points[index]
                            let path = UIBezierPath(arcCenter: point.event.location,
                                                    radius: 4,
                                                    startAngle: 0,
                                                    endAngle: CGFloat(Double.pi * 2),
                                                    clockwise: true)
                            path.stroke()
                        } else {
                            let point = stroke.points.last!
                            UIBezierPath(rect: CGRect(origin: point.event.location, size: CGSize.zero).expand(by: 4)).stroke()
                        }
                    }
                } else {
                    for point in stroke.points {
                        let path = UIBezierPath(arcCenter: point.event.location,
                                                radius: 4,
                                                startAngle: 0,
                                                endAngle: CGFloat(Double.pi * 2),
                                                clockwise: true)
                        path.stroke()
                    }
                }
            }

            for delta in deltas {
                switch delta {
                case .addedPolyline(let polylineIndex):
                    draw(stroke: originalStrokes[polylineIndex], indexSet: nil)
                case .updatedPolyline(let polylineIndex, let indexSet):
                    draw(stroke: originalStrokes[polylineIndex], indexSet: indexSet)
                default:
                    break
                }
            }
        }

        deltas?.removeAll()
    }
}
