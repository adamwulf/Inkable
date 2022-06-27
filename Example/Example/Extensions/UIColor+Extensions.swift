//
//  UIColor+Extensions.swift
//  Example
//
//  Created by Adam Wulf on 6/27/22.
//

import UIKit

extension UIColor {
    static let isFinal = UIColor.red
    static let isUpdate = UIColor.green.darker()
    static let isPrediction = UIColor.blue

    func lighter(by percentage: CGFloat = 0.3) -> UIColor {
        return self.adjustBrightness(by: abs(percentage))
    }

    func darker(by percentage: CGFloat = 0.3) -> UIColor {
        return self.adjustBrightness(by: -abs(percentage))
    }

    func adjustBrightness(by percentage: CGFloat = 0.3) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if self.getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
            if b > 0.0, percentage < 0 {
                let newB: CGFloat = max(min(b + percentage*b, 1.0), 0.0)
                return UIColor(hue: h, saturation: s, brightness: newB, alpha: a)
            } else if b < 1.0, percentage > 0 {
                let newB: CGFloat = max(min(b + percentage*b, 1.0), 0.0)
                return UIColor(hue: h, saturation: s, brightness: newB, alpha: a)
            } else {
                let newS: CGFloat = min(max(s - percentage*s, 0.0), 1.0)
                return UIColor(hue: h, saturation: newS, brightness: b, alpha: a)
            }
        }
        return self
    }
}
