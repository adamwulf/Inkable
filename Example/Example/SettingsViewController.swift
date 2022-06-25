//
//  SettingsViewController.swift
//  Example
//
//  Created by Adam Wulf on 6/25/22.
//

import Foundation
import UIKit

@objc protocol SettingsViewControllerDelegate {
    func visibilityChanged(pointsEnabled: Bool, linesEnabled: Bool, curvesEnabled: Bool)
    func smoothingChanged(savitzkyGolayEnabled: Bool)
}

class SettingsViewController: UITableViewController {

    @IBOutlet var settingsDelegate: SettingsViewControllerDelegate?

    private var pointsEnabled: Bool = true
    private var linesEnabled: Bool = true
    private var curvesEnabled: Bool = true
    private var savitzkyGolayEnabled: Bool = true

    private static let SimpleCell = "SimpleCell"

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.SimpleCell)
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 3
        } else if section == 1 {
            return 1
        }
        assertionFailure()
        return 0
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Visibility"
        } else if section == 1 {
            return "Smoothing"
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Self.SimpleCell) else {
            assertionFailure()
            return UITableViewCell()
        }
        var content = cell.defaultContentConfiguration()

        if indexPath.section == 0 {
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
        } else if indexPath.section == 1 {
            content.text = "Savitzky-Golay"
            cell.accessoryType = savitzkyGolayEnabled ? .checkmark : .none
        }

        cell.contentConfiguration = content

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.section == 0 {
            if indexPath.row == 0 {
                pointsEnabled = !pointsEnabled
            } else if indexPath.row == 1 {
                linesEnabled = !linesEnabled
            } else if indexPath.row == 2 {
                curvesEnabled = !curvesEnabled
            }

            settingsDelegate?.visibilityChanged(pointsEnabled: pointsEnabled,
                                                linesEnabled: linesEnabled,
                                                curvesEnabled: curvesEnabled)
        } else if indexPath.section == 1 {
            if indexPath.row == 0 {
                savitzkyGolayEnabled = !savitzkyGolayEnabled
            }
            settingsDelegate?.smoothingChanged(savitzkyGolayEnabled: savitzkyGolayEnabled)
        }

        tableView.reloadRows(at: [indexPath], with: .automatic)

    }
}
