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

    let eventView = UIView()
    let pointsView = PointsView(frame: .zero)
    var linesView = PolylineView(frame: .zero)
    var curvesView = BezierView(frame: .zero)

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
        lineStream.addConsumer(douglasPeucker)
        lineStream.addConsumer(linesView)
        douglasPeucker.addConsumer(pointDistance)
        pointDistance.addConsumer(savitzkyGolay)
        savitzkyGolay.addConsumer(bezierStream)
        bezierStream.addConsumer(attributeStream)
        bezierStream.addConsumer(curvesView)
        attributeStream.addConsumer { (_) in
            // noop
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(eventView)
        view.addSubview(pointsView)
        view.addSubview(linesView)
        view.addSubview(curvesView)

        eventView.layoutHuggingParent(safeArea: true)
        pointsView.layoutHuggingParent(safeArea: true)
        linesView.layoutHuggingParent(safeArea: true)
        curvesView.layoutHuggingParent(safeArea: true)

        eventView.addGestureRecognizer(touchEventStream.gesture)
    }

    @objc override func didRequestClear(_ sender: UIView) {
        self.pointsView.reset()
        self.linesView.reset()
        self.curvesView.reset()
        super.didRequestClear(sender)
    }
}

extension DebugViewController: SettingsViewControllerDelegate {
    func settingsChanged(pointsEnabled: Bool, linesEnabled: Bool, curvesEnabled: Bool) {
        pointsView.isHidden = !pointsEnabled
        linesView.isHidden = !linesEnabled
        curvesView.isHidden = !curvesEnabled
    }
}
