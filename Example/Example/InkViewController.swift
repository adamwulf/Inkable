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

    let eventView = UIView()
    let pointsView = PointsView(frame: .zero)
    let savitzkyGolayView = PolylineView(frame: .zero, color: .purple)
    let douglasPeuckerView = PolylineView(frame: .zero, color: .purple)
    var linesView = PolylineView(frame: .zero)
    var curvesView = BezierView(frame: .zero)

    let savitzkyGolay = SavitzkyGolay()
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
        savitzkyGolay.addConsumer(savitzkyGolayView)
        bezierStream.addConsumer(curvesView)
        bezierStream.addConsumer { (_) in
            // noop
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        pointsView.setNeedsDisplay()
        linesView.setNeedsDisplay()
        savitzkyGolayView.setNeedsDisplay()
        curvesView.setNeedsDisplay()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(eventView)
        view.addSubview(pointsView)
        view.addSubview(linesView)
        view.addSubview(savitzkyGolayView)
        view.addSubview(curvesView)

        eventView.layoutHuggingParent(safeArea: true)
        pointsView.layoutHuggingParent(safeArea: true)
        linesView.layoutHuggingParent(safeArea: true)
        savitzkyGolayView.layoutHuggingParent(safeArea: true)
        curvesView.layoutHuggingParent(safeArea: true)
    }

    func reset() {
        self.pointsView.reset()
        self.linesView.reset()
        self.savitzkyGolayView.reset()
        self.curvesView.reset()
    }

    func clearTransform() {
        pointsView.renderTransform = .identity
        linesView.renderTransform = .identity
        savitzkyGolayView.renderTransform = .identity
        curvesView.renderTransform = .identity
    }

    var isFitToSize: Bool {
        return pointsView.renderTransform != .identity
    }

    func toggleSizeToFit() {
        guard pointsView.renderTransform == .identity else {
            pointsView.renderTransform = .identity
            linesView.renderTransform = .identity
            savitzkyGolayView.renderTransform = .identity
            curvesView.renderTransform = .identity
            return
        }
        let targetFrame = curvesView.model.paths.reduce(CGRect.null, { $0.union($1.bounds) }).expand(by: 10)
        guard targetFrame != .null else { return }

        let targetSize = view.bounds.expand(by: -50)
        let scale = max(targetFrame.size.width / targetSize.width, targetFrame.size.height / targetSize.height)
        let transform: CGAffineTransform = .identity
            .scaledBy(x: 1 / scale, y: 1 / scale)
            .translatedBy(x: -targetFrame.origin.x, y: -targetFrame.origin.y)
        pointsView.renderTransform = transform
        linesView.renderTransform = transform
        savitzkyGolayView.renderTransform = transform
        curvesView.renderTransform = transform
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
        savitzkyGolayView.isHidden = !savitzkyGolay.enabled || linesView.isHidden
    }

    func smoothingChanged(savitzkyGolayEnabled: Bool, douglasPeuckerEnabled: Bool) {
        savitzkyGolay.enabled = savitzkyGolayEnabled
        savitzkyGolayView.isHidden = !savitzkyGolay.enabled || linesView.isHidden
        douglasPeucker.enabled = douglasPeuckerEnabled
        douglasPeuckerView.isHidden = !douglasPeucker.enabled || linesView.isHidden
    }
}
