//
//  SplitViewController.swift
//  Example
//
//  Created by Adam Wulf on 6/25/22.
//

import Foundation
import UIKit

class SplitViewController: UISplitViewController {

    private var settingsViewController: SettingsViewController? {
        guard let nav = self.viewController(for: .supplementary) as? UINavigationController else { return nil }
        return nav.viewControllers.first as? SettingsViewController
    }

    private var inkViewController: InkViewController? {
        return self.viewController(for: .secondary) as? InkViewController
    }

    private var eventsViewController: EventListViewController? {
        guard let nav = self.viewController(for: .primary) as? UINavigationController else { return nil }
        return nav.viewControllers.first as? EventListViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        settingsViewController?.settingsDelegate = inkViewController
    }
}
