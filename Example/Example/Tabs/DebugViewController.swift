//
//  DebugViewController.swift
//  DrawUIExample
//
//  Created by Adam Wulf on 8/16/20.
//

import UIKit
import Inkable

class DebugViewController: BaseViewController {

    let touchPathStream = TouchPathStream()
    let lineStream = PolylineStream()
    let bezierStream = BezierStream(smoother: AntigrainSmoother())
    let attributeStream = AttributesStream()
    @IBOutlet var debugView: DebugView?

    let eventView = UIView()
    let pointsView = PointsView(frame: .zero)
    var linesView = PolylineView(frame: .zero)
    var curvesView: UIView?

    let savitzkyGolay = NaiveSavitzkyGolay()
    let douglasPeucker = NaiveDouglasPeucker()
    let pointDistance = NaivePointDistance()

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        touchEventStream.addConsumer { (updatedEvents) in
            self.allEvents.append(contentsOf: updatedEvents)
        }
        touchEventStream.addConsumer(touchPathStream)
        touchPathStream.addConsumer(lineStream)
        touchPathStream.addConsumer(pointsView)
        var strokeOutput = PolylineStream.Produces(lines: [], deltas: [])
        lineStream.addConsumer { (input) in
            strokeOutput = input
        }
        lineStream.addConsumer(douglasPeucker)
        lineStream.addConsumer(linesView)
        douglasPeucker.addConsumer(pointDistance)
        pointDistance.addConsumer(savitzkyGolay)
        savitzkyGolay.addConsumer(bezierStream)
        bezierStream.addConsumer(attributeStream)
        attributeStream.addConsumer { (bezierOutput) in
            self.debugView?.smoothStrokes = bezierOutput.paths
            self.debugView?.originalStrokes = strokeOutput.lines
            self.debugView?.add(deltas: strokeOutput.deltas)
            self.debugView?.setNeedsDisplay()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(eventView)
        view.addSubview(pointsView)
        view.addSubview(linesView)

        eventView.layoutHuggingParent(safeArea: true)
        pointsView.layoutHuggingParent(safeArea: true)
        linesView.layoutHuggingParent(safeArea: true)

        eventView.addGestureRecognizer(touchEventStream.gesture)
    }

    @objc override func didRequestClear(_ sender: UIView) {
        self.debugView?.reset()
        super.didRequestClear(sender)
    }
}

extension DebugViewController: SettingsViewControllerDelegate {
    func settingsChanged(pointsEnabled: Bool, linesEnabled: Bool, curvesEnabled: Bool) {
        pointsView.isHidden = !pointsEnabled
        linesView.isHidden = !linesEnabled
        curvesView?.isHidden = !curvesEnabled
        debugView?.isHidden = !curvesEnabled
    }
}
