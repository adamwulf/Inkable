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
    let pointsView = PointsView(frame: .zero)
    let savitzkyGolayView = PolylineView(frame: .zero, color: .purple)
    let douglasPeuckerView = PolylineView(frame: .zero, color: .purple)
    var linesView = PolylineView(frame: .zero)
    var curvesView = BezierView(frame: .zero)

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        let inkModel = AppDelegate.shared.inkModel
        inkModel.touchPathStream.addConsumer(pointsView)
        inkModel.lineStream.addConsumer(linesView)
        inkModel.savitzkyGolay.addConsumer(savitzkyGolayView)
        inkModel.bezierStream.addConsumer(curvesView)
        eventView.addGestureRecognizer(inkModel.touchEventStream.gesture)
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

        AppDelegate.shared.inkModel.touchEventStream.addConsumer({ _ in }, reset: { [weak self] in
            self?.reset()
        })
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
        let inkModel = AppDelegate.shared.inkModel
        savitzkyGolayView.isHidden = !inkModel.savitzkyGolay.enabled || linesView.isHidden
    }

    func smoothingChanged(savitzkyGolayEnabled: Bool, douglasPeuckerEnabled: Bool) {
        let inkModel = AppDelegate.shared.inkModel
        inkModel.savitzkyGolay.enabled = savitzkyGolayEnabled
        savitzkyGolayView.isHidden = !inkModel.savitzkyGolay.enabled || linesView.isHidden
        inkModel.douglasPeucker.enabled = douglasPeuckerEnabled
        douglasPeuckerView.isHidden = !inkModel.douglasPeucker.enabled || linesView.isHidden
    }
}
