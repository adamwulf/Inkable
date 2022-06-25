//
//  SettingsViewController.swift
//  Example
//
//  Created by Adam Wulf on 6/25/22.
//

import Foundation
import UIKit

@objc protocol SettingsViewControllerDelegate {
    func settingsChanged(pointsEnabled: Bool, linesEnabled: Bool, curvesEnabled: Bool)
}

class SettingsViewController: UITableViewController {

    @IBOutlet var settingsDelegate: SettingsViewControllerDelegate?

    private var pointsEnabled: Bool = true
    private var linesEnabled: Bool = true
    private var curvesEnabled: Bool = true

    private static let SimpleCell = "SimpleCell"

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.SimpleCell)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Self.SimpleCell) else {
            assertionFailure()
            return UITableViewCell()
        }
        var content = cell.defaultContentConfiguration()

        if indexPath.row == 0 {
            content.text = "Points"
            cell.accessoryType = pointsEnabled ? .checkmark : .none
        } else if indexPath.row == 1 {
            content.text = "Lines"
            cell.accessoryType = linesEnabled ? .checkmark : .none
        } else if indexPath.row == 2 {
            content.text = "Curves"
            cell.accessoryType = curvesEnabled ? .checkmark : .none
        } else {
            assertionFailure()
            content.text = "Unknown"
        }

        cell.contentConfiguration = content

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.row == 0 {
            pointsEnabled = !pointsEnabled
        } else if indexPath.row == 1 {
            linesEnabled = !linesEnabled
        } else if indexPath.row == 2 {
            curvesEnabled = !curvesEnabled
        }

        tableView.reloadRows(at: [indexPath], with: .automatic)

        settingsDelegate?.settingsChanged(pointsEnabled: pointsEnabled, linesEnabled: linesEnabled, curvesEnabled: curvesEnabled)
    }
}
