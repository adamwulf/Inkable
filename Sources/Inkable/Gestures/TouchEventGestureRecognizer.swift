//
//  TouchEventGestureRecognizer.swift
//  Inkable
//
//  Created by Adam Wulf on 8/16/20.
//

import UIKit

public class TouchEventGestureRecognizer: UIGestureRecognizer, UIGestureRecognizerDelegate {

    // MARK: - Private
    public var callback: (([TouchEvent]) -> Void)?
    private var activeTouches: Set<UITouch>

    // MARK: - Init

    public override init(target: Any?, action: Selector?) {
        self.activeTouches = Set()

        super.init(target: target, action: action)

        cancelsTouchesInView = false
        delaysTouchesBegan = false
        delaysTouchesEnded = false
        allowedTouchTypes = [NSNumber(value: UITouch.TouchType.direct.rawValue), NSNumber(value: UITouch.TouchType.stylus.rawValue)]
        delegate = self
    }

    // MARK: - Process Touch Events

    private func process(touches: Set<UITouch>, with event: UIEvent?, isUpdate: Bool) {
        guard let view = view else { return }

        var allTouchEvents: [TouchEvent] = []

        for touch in touches {
            var coalesced = event?.coalescedTouches(for: touch) ?? [touch]

            if coalesced.isEmpty {
                coalesced = [touch]
            }

            for coalescedTouch in coalesced {
                allTouchEvents.append(TouchEvent(coalescedTouch: coalescedTouch,
                                                 touch: touch,
                                                 in: view,
                                                 isUpdate: isUpdate,
                                                 isPrediction: false))
            }

            let predicted = event?.predictedTouches(for: touch) ?? []

            for predictedTouch in predicted {
                allTouchEvents.append(TouchEvent(coalescedTouch: predictedTouch,
                                                 touch: touch,
                                                 in: view,
                                                 isUpdate: isUpdate,
                                                 isPrediction: true))
            }
        }

        callback?(allTouchEvents)
    }

    // MARK: - UIGestureRecognizer

    public override func canBePrevented(by preventingGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }

    public override func shouldBeRequiredToFail(by otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }

    public override func touchesEstimatedPropertiesUpdated(_ touches: Set<UITouch>) {
        process(touches: touches, with: nil, isUpdate: true)
    }

    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        activeTouches.formUnion(touches)

        super.touchesBegan(touches, with: event)
        process(touches: touches, with: event, isUpdate: false)
        state = .began
    }

    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesMoved(touches, with: event)
        process(touches: touches, with: event, isUpdate: false)
        state = .changed
    }

    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        activeTouches.subtract(touches)

        super.touchesEnded(touches, with: event)
        process(touches: touches, with: event, isUpdate: false)

        if activeTouches.isEmpty {
            state = .ended
        } else {
            state = .changed
        }
    }

    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        activeTouches.subtract(touches)

        super.touchesCancelled(touches, with: event)
        process(touches: touches, with: event, isUpdate: false)

        if activeTouches.isEmpty {
            state = .ended
        } else {
            state = .changed
        }
    }
}

// MARK: - UIGestureRecognizer (Delegate)

extension TouchEventGestureRecognizer {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return false
    }
}
