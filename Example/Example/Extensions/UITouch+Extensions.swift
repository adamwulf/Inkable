//
//  UITouch+Extensions.swift
//  Example
//
//  Created by Adam Wulf on 6/28/22.
//

import UIKit

extension UITouch.Phase {
    var stringValue: String {
        switch self {
        case .began:
            return "began"
        case .moved:
            return "moved"
        case .stationary:
            return "stationary"
        case .ended:
            return "ended"
        case .cancelled:
            return "cancelled"
        case .regionEntered:
            return "region entered"
        case .regionMoved:
            return "region moved"
        case .regionExited:
            return "region exited"
        @unknown default:
            return "unknown"
        }
    }
}
