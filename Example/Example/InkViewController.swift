//
//  InkViewController.swift
//  DrawUIExample
//
//  Created by Adam Wulf on 8/16/20.
//

import UIKit
import Inkable

class InkViewController: UIViewController {

    let eventView = UIView()
    let pointsEventsView = PointsView(frame: .zero)
    let pointsSavitzkyGolayView = PointsView(frame: .zero)
    let pointsDouglasPeukerView = PointsView(frame: .zero)

    let savitzkyGolayView = PolylineView(frame: .zero, color: .purple)
    let douglasPeuckerView = PolylineView(frame: .zero, color: .purple)
    var linesView = PolylineView(frame: .zero)
    var curvesView = BezierView(frame: .zero)

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        let inkModel = AppDelegate.shared.inkModel
        // points
        inkModel.lineStream.addConsumer(pointsEventsView)
        inkModel.savitzkyGolay.addConsumer(pointsSavitzkyGolayView)
        inkModel.douglasPeucker.addConsumer(pointsDouglasPeukerView)

        // lines
        inkModel.lineStream.addConsumer(linesView)
        inkModel.savitzkyGolay.addConsumer(savitzkyGolayView)

        // curves
        inkModel.bezierStream.addConsumer(curvesView)
        eventView.addGestureRecognizer(inkModel.touchEventStream.gesture)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        pointsEventsView.setNeedsDisplay()
        linesView.setNeedsDisplay()
        savitzkyGolayView.setNeedsDisplay()
        curvesView.setNeedsDisplay()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(eventView)
        view.addSubview(pointsEventsView)
        view.addSubview(pointsSavitzkyGolayView)
        view.addSubview(pointsDouglasPeukerView)
        view.addSubview(linesView)
        view.addSubview(savitzkyGolayView)
        view.addSubview(curvesView)

        eventView.layoutHuggingParent(safeArea: true)
        pointsEventsView.layoutHuggingParent(safeArea: true)
        pointsSavitzkyGolayView.layoutHuggingParent(safeArea: true)
        pointsDouglasPeukerView.layoutHuggingParent(safeArea: true)
        linesView.layoutHuggingParent(safeArea: true)
        savitzkyGolayView.layoutHuggingParent(safeArea: true)
        curvesView.layoutHuggingParent(safeArea: true)

        AppDelegate.shared.inkModel.touchEventStream.addConsumer({ _ in }, reset: { [weak self] in
            self?.reset()
        })
    }

    func reset() {
//        self.pointsEventsView.reset()
//        self.linesView.reset()
//        self.savitzkyGolayView.reset()
//        self.curvesView.reset()
    }

    func clearTransform() {
        pointsEventsView.renderTransform = .identity
        pointsSavitzkyGolayView.renderTransform = .identity
        pointsDouglasPeukerView.renderTransform = .identity
        linesView.renderTransform = .identity
        savitzkyGolayView.renderTransform = .identity
        curvesView.renderTransform = .identity
    }

    var isFitToSize: Bool {
        return pointsEventsView.renderTransform != .identity
    }

    func toggleSizeToFit() {
        guard pointsEventsView.renderTransform == .identity else {
            pointsEventsView.renderTransform = .identity
            pointsSavitzkyGolayView.renderTransform = .identity
            pointsDouglasPeukerView.renderTransform = .identity
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
        pointsEventsView.renderTransform = transform
        pointsSavitzkyGolayView.renderTransform = transform
        pointsDouglasPeukerView.renderTransform = transform
        linesView.renderTransform = transform
        savitzkyGolayView.renderTransform = transform
        curvesView.renderTransform = transform
    }
}

extension InkViewController {
    func clearAllData() {
        self.reset()
    }

    func visibilityChanged(_ viewSettings: ViewSettings) {
        pointsEventsView.isHidden = viewSettings.pointVisibility != .originalEvents
        pointsSavitzkyGolayView.isHidden = viewSettings.pointVisibility != .savitzkeyGolay
        pointsDouglasPeukerView.isHidden = viewSettings.pointVisibility != .douglasPeuker
        linesView.isHidden = viewSettings.lineVisiblity != .douglasPeuker
        curvesView.isHidden = viewSettings.curveVisibility != .bezier
        savitzkyGolayView.isHidden = viewSettings.lineVisiblity != .savitzkeyGolay
        douglasPeuckerView.isHidden = viewSettings.lineVisiblity != .douglasPeuker
        let inkModel = AppDelegate.shared.inkModel
        savitzkyGolayView.isHidden = !inkModel.savitzkyGolay.enabled || linesView.isHidden
    }

    func smoothingChanged(savitzkyGolayEnabled: Bool, douglasPeuckerEnabled: Bool) {
        let inkModel = AppDelegate.shared.inkModel
        inkModel.savitzkyGolay.enabled = savitzkyGolayEnabled
        inkModel.douglasPeucker.enabled = douglasPeuckerEnabled
    }
}
