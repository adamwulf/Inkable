//
//  ClippedBezierViewController.swift
//  DrawUIExample
//
//  Created by Adam Wulf on 4/4/21.
//

import UIKit
import Inkable
import MMSwiftToolbox

class ClippedBezierViewController: BaseViewController {

    enum ToolIndex: Int {
        case pen = 0
        case marker = 1
        case highlighter = 2
        case eraser = 3

        var style: AttributesStream.ToolStyle {
            switch self {
            case .pen:
                return AttributesStream.ToolStyle(width: 1.5, color: .black)
            case .marker:
                return AttributesStream.ToolStyle(width: 2.5, color: .blue)
            case .highlighter:
                return AttributesStream.ToolStyle(width: 8, color: UIColor.green.withAlphaComponent(0.5))
            case .eraser:
                return AttributesStream.ToolStyle(width: 40, color: nil)
            }
        }
    }

    let touchPathStream = TouchPathStream()
    let lineStream = PolylineStream()
    let savitzkyGolay = NaiveSavitzkyGolay()
    let bezierStream = BezierStream(smoother: AntigrainSmoother())
    let attributeStream = AttributesStream()
    let clippedStream = ClippedBezierStream()
    @IBOutlet var pathView: ClippedBezierView!
    @IBOutlet var toolPicker: UISegmentedControl!

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        touchEventStream.addConsumer(touchPathStream)
        touchPathStream.addConsumer(lineStream)
        lineStream.addConsumer(savitzkyGolay)
        savitzkyGolay.addConsumer(bezierStream)
        bezierStream.addConsumer(attributeStream)
        attributeStream.addConsumer(clippedStream)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        clippedStream.addConsumer(pathView)
        pathView?.addGestureRecognizer(touchEventStream.gesture)
    }

    // MARK: - Actions

    @IBAction func toolDidChange(_ sender: Any) {
        guard
            let tool = BezierViewController.ToolIndex(rawValue: toolPicker.selectedSegmentIndex)
        else {
            return
        }
        touchEventStream.process(events: [ToolEvent(style: tool.style)])
    }
}
