//
//  InkViewController.swift
//  DrawUIExample
//
//  Created by Adam Wulf on 8/16/20.
//

import UIKit
import Inkable
import SwiftToolbox

class InkViewController: UIViewController {

    let eventView = UIView()
    let pointsEventsView = PointsView(frame: .zero)
    let pointsSavitzkyGolayView = PointsView(frame: .zero)
    let pointsDouglasPeukerView = PointsView(frame: .zero)

    var linesEventsView = PolylineView(frame: .zero)
    let linesSavitzkyGolayView = PolylineView(frame: .zero, color: .purple)
    let linesDouglasPeuckerView = PolylineView(frame: .zero, color: .purple)

    let bezierStreamEvents: BezierStream
    let bezierStreamSavitzkyGolay: BezierStream

    var curvesEventsView = BezierView(frame: .zero)
    var curvesSavitzkyGolayView = BezierView(frame: .zero)
    var curvesDouglasPeuckerView = BezierView(frame: .zero)

    required init?(coder: NSCoder) {
        let inkModel = AppDelegate.shared.inkModel
        bezierStreamEvents = BezierStream(smoother: inkModel.bezierStream.smoother)
        bezierStreamSavitzkyGolay = BezierStream(smoother: inkModel.bezierStream.smoother)

        super.init(coder: coder)

        // points
        inkModel.lineStream.addConsumer(pointsEventsView)
        inkModel.savitzkyGolay.addConsumer(pointsSavitzkyGolayView)
        inkModel.douglasPeucker.addConsumer(pointsDouglasPeukerView)

        // lines
        inkModel.lineStream.addConsumer(linesEventsView)
        inkModel.savitzkyGolay.addConsumer(linesSavitzkyGolayView)
        inkModel.douglasPeucker.addConsumer(linesDouglasPeuckerView)

        // curves

        inkModel.lineStream
            .nextStep(bezierStreamEvents)
            .addConsumer(curvesEventsView)
        inkModel.savitzkyGolay
            .nextStep(bezierStreamSavitzkyGolay)
            .addConsumer(curvesSavitzkyGolayView)
        inkModel.bezierStream.addConsumer(curvesDouglasPeuckerView)

        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(didPinch))
        pinchGesture.delegate = self
        pinchGesture.cancelsTouchesInView = true
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(didPan))
        panGesture.minimumNumberOfTouches = 2
        panGesture.delegate = self
        panGesture.cancelsTouchesInView = true
        inkModel.touchEventStream.gesture.delegate = self

        eventView.addGestureRecognizer(inkModel.touchEventStream.gesture)
        eventView.addGestureRecognizer(pinchGesture)
        eventView.addGestureRecognizer(panGesture)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        pointsEventsView.setNeedsDisplay()
        pointsSavitzkyGolayView.setNeedsDisplay()
        pointsDouglasPeukerView.setNeedsDisplay()
        linesEventsView.setNeedsDisplay()
        linesSavitzkyGolayView.setNeedsDisplay()
        linesDouglasPeuckerView.setNeedsDisplay()
        curvesEventsView.setNeedsDisplay()
        curvesSavitzkyGolayView.setNeedsDisplay()
        curvesDouglasPeuckerView.setNeedsDisplay()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(eventView)
        view.addSubview(pointsEventsView)
        view.addSubview(pointsSavitzkyGolayView)
        view.addSubview(pointsDouglasPeukerView)
        view.addSubview(linesEventsView)
        view.addSubview(linesSavitzkyGolayView)
        view.addSubview(linesDouglasPeuckerView)
        view.addSubview(curvesEventsView)
        view.addSubview(curvesSavitzkyGolayView)
        view.addSubview(curvesDouglasPeuckerView)

        eventView.layoutHuggingParent(safeArea: true)
        pointsEventsView.layoutHuggingParent(safeArea: true)
        pointsSavitzkyGolayView.layoutHuggingParent(safeArea: true)
        pointsDouglasPeukerView.layoutHuggingParent(safeArea: true)
        linesEventsView.layoutHuggingParent(safeArea: true)
        linesSavitzkyGolayView.layoutHuggingParent(safeArea: true)
        linesDouglasPeuckerView.layoutHuggingParent(safeArea: true)
        curvesEventsView.layoutHuggingParent(safeArea: true)
        curvesSavitzkyGolayView.layoutHuggingParent(safeArea: true)
        curvesDouglasPeuckerView.layoutHuggingParent(safeArea: true)
    }

    func clearTransform() {
        updateTransform(.identity)
    }

    var isFitToSize: Bool {
        return pointsEventsView.renderTransform != .identity
    }

    func toggleSizeToFit() {
        guard pointsEventsView.renderTransform == .identity else {
            clearTransform()
            return
        }
        let targetFrame = curvesDouglasPeuckerView.model.paths.reduce(CGRect.null, { $0.union($1.bounds) }).expand(by: 10)
        guard targetFrame != .null else { return }

        let targetSize = view.bounds.expand(by: -50)
        let scale = max(targetFrame.size.width / targetSize.width, targetFrame.size.height / targetSize.height)
        let transform: CGAffineTransform = .identity
            .scaledBy(x: 1 / scale, y: 1 / scale)
            .translatedBy(x: -targetFrame.origin.x, y: -targetFrame.origin.y)
        updateTransform(transform)
    }

    // MARK: - Actions

    private var activeGestureCount: Int = 0
    private var originalRenderTransform: CGAffineTransform = .identity

    private func adjustCount(for gesture: UIGestureRecognizer) {
        guard gesture.state != .changed else { return }
        if gesture.state == .began {
            activeGestureCount += 1
        } else if [.ended, .cancelled].contains(gesture.state) {
            activeGestureCount -= 1
        }
        if activeGestureCount > 0 {
            AppDelegate.shared.inkModel.touchEventStream.gesture.fail()
        }
    }

    @objc func didPinch(_ gesture: UIPinchGestureRecognizer) {
        adjustCount(for: gesture)
        let updatedTransform: CGAffineTransform

        switch gesture.state {
        case .possible:
            return
        case .began:
            originalRenderTransform = pointsEventsView.renderTransform
            updatedTransform = originalRenderTransform
        case .changed, .ended:
            let location = gesture.location(in: eventView)
            updatedTransform = originalRenderTransform
                .translated(by: location)
                .scaled(by: gesture.scale)
                .translated(by: -location)
        case .cancelled, .failed:
            updatedTransform = originalRenderTransform
        default:
            return
        }

        updateTransform(updatedTransform)
    }

    @objc func didPan(_ gesture: UIPanGestureRecognizer) {
        adjustCount(for: gesture)
        guard [.changed, .ended].contains(gesture.state) else { return }
        let originalTranslation = gesture.translation(in: eventView) / originalRenderTransform.scale
        originalRenderTransform = originalRenderTransform.translated(by: originalTranslation)

        let translation = gesture.translation(in: eventView) / pointsEventsView.renderTransform.scale
        let transform = pointsEventsView.renderTransform.translated(by: translation)
        updateTransform(transform)
        gesture.setTranslation(.zero, in: eventView)
    }

    // MARK: - Private

    private func updateTransform(_ transform: CGAffineTransform) {
        pointsEventsView.renderTransform = transform
        pointsSavitzkyGolayView.renderTransform = transform
        pointsDouglasPeukerView.renderTransform = transform
        linesEventsView.renderTransform = transform
        linesSavitzkyGolayView.renderTransform = transform
        linesDouglasPeuckerView.renderTransform = transform
        curvesEventsView.renderTransform = transform
        curvesSavitzkyGolayView.renderTransform = transform
        curvesDouglasPeuckerView.renderTransform = transform
    }
}

extension InkViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        let eventGesture = AppDelegate.shared.inkModel.touchEventStream.gesture
        return gestureRecognizer != eventGesture && otherGestureRecognizer != eventGesture
    }
}

extension InkViewController {
    func visibilityChanged(_ viewSettings: ViewSettings) {
        pointsEventsView.isHidden = viewSettings.pointVisibility != .originalEvents
        pointsSavitzkyGolayView.isHidden = viewSettings.pointVisibility != .savitzkeyGolay
        pointsDouglasPeukerView.isHidden = viewSettings.pointVisibility != .douglasPeuker
        linesEventsView.isHidden = viewSettings.lineVisiblity != .originalEvents
        linesSavitzkyGolayView.isHidden = viewSettings.lineVisiblity != .savitzkeyGolay
        linesDouglasPeuckerView.isHidden = viewSettings.lineVisiblity != .douglasPeuker
        curvesEventsView.isHidden = viewSettings.curveVisibility != .originalEvents
        curvesSavitzkyGolayView.isHidden = viewSettings.curveVisibility != .savitzkeyGolay
        curvesDouglasPeuckerView.isHidden = viewSettings.curveVisibility != .douglasPeuker

        bezierStreamEvents.isEnabled = !curvesEventsView.isHidden
        bezierStreamSavitzkyGolay.isEnabled = !curvesSavitzkyGolayView.isHidden
        AppDelegate.shared.inkModel.bezierStream.isEnabled = !curvesDouglasPeuckerView.isHidden
    }

    func smoothingChanged(savitzkyGolayEnabled: Bool, douglasPeuckerEnabled: Bool) {
        let inkModel = AppDelegate.shared.inkModel
        inkModel.savitzkyGolay.isEnabled = savitzkyGolayEnabled
        inkModel.douglasPeucker.isEnabled = douglasPeuckerEnabled
    }
}
