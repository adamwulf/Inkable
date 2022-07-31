//
//  TouchEventGestureRecognizer.swift
//  Inkable
//
//  Created by Adam Wulf on 8/16/20.
//

import UIKit

public class TouchEventGestureRecognizer: UIGestureRecognizer, UIGestureRecognizerDelegate {

    // MARK: - Private
    public var callback: (([DrawEvent]) -> Void)?
    private var activeTouches: Set<UITouch>
    private var proxyDelegate: UIGestureRecognizerDelegate?

    // MARK: - Init

    override public var delegate: UIGestureRecognizerDelegate? {
        get {
            return proxyDelegate
        }
        set {
            proxyDelegate = newValue
        }
    }

    public override init(target: Any?, action: Selector?) {
        self.activeTouches = Set()

        super.init(target: target, action: action)

        cancelsTouchesInView = false
        delaysTouchesBegan = false
        delaysTouchesEnded = false
        allowedTouchTypes = [NSNumber(value: UITouch.TouchType.direct.rawValue), NSNumber(value: UITouch.TouchType.stylus.rawValue)]
        super.delegate = self
    }

    // MARK: - Process Touch Events

    private func process(touches: Set<UITouch>, with event: UIEvent?, isUpdate: Bool) {
        guard let view = view else { return }

        var allTouchEvents: [DrawEvent] = []

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

        allTouchEvents.append(GestureCallbackEvent())

        callback?(allTouchEvents)
    }

    public func fail() {
        guard let view = view, !activeTouches.isEmpty else { return }
        callback?(activeTouches.map({ touch in
            return TouchEvent(coalescedTouch: touch, touch: touch, in: view, isUpdate: false, isPrediction: false, phase: .cancelled)
        }))
        state = .failed
        activeTouches.removeAll()
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
        return proxyDelegate?.gestureRecognizer?(gestureRecognizer, shouldRequireFailureOf: otherGestureRecognizer) ?? false
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                                  shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return proxyDelegate?.gestureRecognizer?(gestureRecognizer, shouldBeRequiredToFailBy: otherGestureRecognizer) ?? false
    }

    @available(iOS 13.4, *)
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive event: UIEvent) -> Bool {
        return proxyDelegate?.gestureRecognizer?(gestureRecognizer, shouldReceive: event) ?? true
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return proxyDelegate?.gestureRecognizer?(gestureRecognizer, shouldReceive: touch) ?? true
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive press: UIPress) -> Bool {
        return proxyDelegate?.gestureRecognizer?(gestureRecognizer, shouldReceive: press) ?? true
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
