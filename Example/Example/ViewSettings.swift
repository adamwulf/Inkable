//
//  ViewSettings.swift
//  Example
//
//  Created by Adam Wulf on 7/30/22.
//

import Foundation

struct ViewSettings {
    enum PolyLineSelection: CaseIterable {
        case none
        case originalEvents
        case savitzkeyGolay
        case douglasPeuker

        var name: String {
            switch self {
            case .none:
                return "None"
            case .originalEvents:
                return "Original Events"
            case .savitzkeyGolay:
                return "Savitzkey-Golay"
            case .douglasPeuker:
                return "Douglas-Peuker"
            }
        }
    }

    enum CurveSelection: CaseIterable {
        case none
        case bezier

        var name: String {
            switch self {
            case .none:
                return "None"
            case .bezier:
                return "Bezier Curves"
            }
        }
    }

    var pointVisibility: PolyLineSelection = .douglasPeuker
    var lineVisiblity: PolyLineSelection = .douglasPeuker
    var curveVisibility: CurveSelection = .bezier
}
