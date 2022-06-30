//
//  SettingsViewController.swift
//  Example
//
//  Created by Adam Wulf on 6/25/22.
//

import Foundation
import UIKit
import Inkable
import UniformTypeIdentifiers

protocol SettingsViewControllerDelegate {
    var isFitToSize: Bool { get }

    func visibilityChanged(pointsEnabled: Bool, linesEnabled: Bool, curvesEnabled: Bool)
    func smoothingChanged(savitzkyGolayEnabled: Bool)
    func clearAllData()
    func importEvents(_ events: [DrawEvent])
    func exportEvents(sender: UIView)
    func toggleSizeToFit()
}

class SettingsViewController: UITableViewController {

    typealias Section = (title: String, options: [Settings])
    enum Settings {
        case showPoints
        case showLines
        case showCurves
        case smoothSavitzkyGolay
        case importEvents
        case exportEvents
        case clearScreen
        case sizeToFit

        var name: String {
            switch self {
            case .showPoints:
                return "Points"
            case .showLines:
                return "Lines"
            case .showCurves:
                return "Curves"
            case .smoothSavitzkyGolay:
                return "Savitzky-Golay"
            case .importEvents:
                return "Import"
            case .exportEvents:
                return "Export"
            case .clearScreen:
                return "Clear"
            case .sizeToFit:
                return "Size to Fit"
            }
        }
    }

    var settingsDelegate: SettingsViewControllerDelegate?

    private let navigation: [Section] = [("Visibility", [.showPoints, .showLines, .showCurves]),
                                         ("Smoothing", [.smoothSavitzkyGolay]),
                                         ("Data", [.importEvents, .exportEvents, .clearScreen, .sizeToFit])]
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
        return navigation.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section >= 0, section < navigation.count else { fatalError() }
        return navigation[section].options.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard section >= 0, section < navigation.count else { return nil }
        return navigation[section].title
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            indexPath.section >= 0, indexPath.section < navigation.count,
            case let section = navigation[indexPath.section],
            indexPath.row >= 0, indexPath.row < section.options.count,
            case let option = section.options[indexPath.row],
            let cell = tableView.dequeueReusableCell(withIdentifier: Self.SimpleCell)
        else {
            assertionFailure()
            return UITableViewCell()
        }
        var content = cell.defaultContentConfiguration()

        content.text = option.name
        switch option {
        case .showPoints:
            cell.accessoryType = pointsEnabled ? .checkmark : .none
        case .showLines:
            cell.accessoryType = linesEnabled ? .checkmark : .none
        case .showCurves:
            cell.accessoryType = curvesEnabled ? .checkmark : .none
        case .smoothSavitzkyGolay:
            cell.accessoryType = savitzkyGolayEnabled ? .checkmark : .none
        case .sizeToFit:
            if let settingsDelegate = settingsDelegate,
               settingsDelegate.isFitToSize {
                content.text = "Original Size"
            }
            cell.accessoryType = .none
        case .importEvents, .exportEvents, .clearScreen:
            cell.accessoryType = .none
            break
        }

        cell.contentConfiguration = content

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard
            indexPath.section >= 0, indexPath.section < navigation.count,
            case let section = navigation[indexPath.section],
            indexPath.row >= 0, indexPath.row < section.options.count,
            case let option = section.options[indexPath.row]
        else {
            return
        }

        func visibilityChanged() {
            self.settingsDelegate?.visibilityChanged(pointsEnabled: self.pointsEnabled,
                                                linesEnabled: self.linesEnabled,
                                                curvesEnabled: self.curvesEnabled)
        }
        func smoothingChanged() {
            self.settingsDelegate?.smoothingChanged(savitzkyGolayEnabled: self.savitzkyGolayEnabled)
        }

        switch option {
        case .showPoints:
            pointsEnabled = !pointsEnabled
            visibilityChanged()
        case .showLines:
            linesEnabled = !linesEnabled
            visibilityChanged()
        case .showCurves:
            curvesEnabled = !curvesEnabled
            visibilityChanged()
        case .smoothSavitzkyGolay:
            savitzkyGolayEnabled = !savitzkyGolayEnabled
            smoothingChanged()
        case .importEvents:
            let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.json, UTType.text], asCopy: true)
            picker.delegate = self
            present(picker, animated: true, completion: nil)
        case .exportEvents:
            guard let cell = tableView.cellForRow(at: indexPath) else { return }
            settingsDelegate?.exportEvents(sender: cell)
        case .clearScreen:
            settingsDelegate?.clearAllData()
        case .sizeToFit:
            settingsDelegate?.toggleSizeToFit()
        }

        tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}

extension SettingsViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        for url in urls {
            guard let data = try? Data(contentsOf: url) else { continue }
            let decoder = JSONDecoder()
            guard let events = try? decoder.decode(Array<TouchEvent>.self, from: data) else { continue }
            settingsDelegate?.importEvents(events)
        }
    }
}
