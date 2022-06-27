//
//  InkViewController.swift
//  DrawUIExample
//
//  Created by Adam Wulf on 8/16/20.
//

import UIKit
import Inkable

class InkViewController: UIViewController {

    weak var eventListViewController: EventListViewController? {
        didSet {
            eventListViewController?.touchEventStream.addConsumer(touchPathStream)
            if let eventListViewController = eventListViewController {
                eventView.addGestureRecognizer(eventListViewController.touchEventStream.gesture)
            }
        }
    }

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
    }

    func reset() {
        self.pointsView.reset()
        self.linesView.reset()
        self.curvesView.reset()
    }
}

extension InkViewController {
    func clearAllData() {
        self.reset()
    }

    func visibilityChanged(pointsEnabled: Bool, linesEnabled: Bool, curvesEnabled: Bool) {
        pointsView.isHidden = !pointsEnabled
        linesView.isHidden = !linesEnabled
        curvesView.isHidden = !curvesEnabled
    }

    func smoothingChanged(savitzkyGolayEnabled: Bool) {
        savitzkyGolay.enabled = savitzkyGolayEnabled
    }
}
