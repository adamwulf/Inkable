//
//  InkModel.swift
//  Example
//
//  Created by Adam Wulf on 7/30/22.
//

import Foundation
import Inkable

class InkModel {
    let touchEventStream = TouchEventStream()
    let touchPathStream = TouchPathStream()
    let lineStream = PolylineStream()
    let pointDistance = NaivePointDistance()
    let savitzkyGolay = SavitzkyGolay()
    let douglasPeucker = IterativeDouglasPeucker()
    let bezierStream = BezierStream(smoother: AntigrainSmoother())

    init() {
        touchEventStream.addConsumer(touchPathStream)
        touchPathStream.addConsumer(lineStream)
        lineStream.addConsumer(pointDistance)
        pointDistance.addConsumer(savitzkyGolay)
        savitzkyGolay.addConsumer(douglasPeucker)
        douglasPeucker.addConsumer(bezierStream)
    }
}
