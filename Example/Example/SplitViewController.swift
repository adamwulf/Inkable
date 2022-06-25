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
        guard let nav = self.viewController(for: .primary) as? UINavigationController else { return nil }
        return nav.viewControllers.first as? SettingsViewController
    }

    private var debugViewController: DebugViewController? {
        return self.viewController(for: .secondary) as? DebugViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        settingsViewController?.settingsDelegate = debugViewController
    }
}
