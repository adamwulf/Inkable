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

protocol SettingsViewControllerDelegate: AnyObject {
    var isFitToSize: Bool { get }

    func visibilityChanged(_ viewSettings: ViewSettings)
    func smoothingChanged(savitzkyGolayEnabled: Bool, douglasPeuckerEnabled: Bool)
    func clearAllData()
    func importEvents(_ events: [DrawEvent])
    func exportEvents(sender: UIView)
    func toggleSizeToFit()
}

class SettingsViewController: UITableViewController {

    typealias Section = (title: String, options: [Rows])
    enum Rows {
        case showOriginalPoints
        case showSavitzkyGolayPoints
        case showDouglasPeuckerPoints
        case showOriginalLines
        case showSavitzkyGolayLines
        case showDouglasPeuckerLines
        case showOriginalCurves
        case showSavitzkyGolayCurves
        case showDouglasPeuckerCurves
        case smoothSavitzkyGolay
        case smoothDouglasPeucker
        case importEvents
        case exportEvents
        case clearScreen
        case sizeToFit

        var name: String {
            switch self {
            case .showOriginalPoints:
                return "Original Events"
            case .showSavitzkyGolayPoints:
                return "Savitzky-Golay"
            case .showDouglasPeuckerPoints:
                return "Douglas-Peucker"
            case .showOriginalLines:
                return "Original Lines"
            case .showSavitzkyGolayLines:
                return "Savitzky-Golay"
            case .showDouglasPeuckerLines:
                return "Douglas-Peucker"
            case .showOriginalCurves:
                return "Original Events"
            case .showSavitzkyGolayCurves:
                return "Savitzky-Golay"
            case .showDouglasPeuckerCurves:
                return "Douglas-Peucker"
            case .smoothSavitzkyGolay:
                return "Savitzky-Golay"
            case .smoothDouglasPeucker:
                return "Douglas-Peucker"
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

    private let navigation: [Section] = [("Point Visibility", [.showOriginalPoints, .showSavitzkyGolayPoints, .showDouglasPeuckerPoints]),
                                         ("Line Visibility", [.showOriginalLines, .showSavitzkyGolayLines, .showDouglasPeuckerLines]),
                                         ("Curve Visibility", [.showOriginalCurves, .showSavitzkyGolayCurves, .showDouglasPeuckerCurves]),
                                         ("Smoothing", [.smoothSavitzkyGolay, .smoothDouglasPeucker]),
                                         ("Data", [.importEvents, .exportEvents, .clearScreen, .sizeToFit])]
    private var viewSettings: ViewSettings = ViewSettings()
    private var savitzkyGolayEnabled: Bool = true
    private var douglasPeuckerEnabled: Bool = true

    private static let SimpleCell = "SimpleCell"

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.SimpleCell)

        NotificationCenter.default.addObserver(forName: .InkControllerDidZoom, object: nil, queue: nil) { [weak self] _ in
            guard let self = self else { return }
            let path = self.navigation.compactMap({ section, sectionNum in
                return section.options.compactMap({ row, rowNum -> IndexPath? in
                    if row == .sizeToFit {
                        return IndexPath(row: rowNum, section: sectionNum)
                    }
                    return nil
                }).first
            })
            guard !path.isEmpty else { return }
            self.tableView.reloadRows(at: path, with: .automatic)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        settingsDelegate?.visibilityChanged(viewSettings)
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
        content.secondaryText = nil
        switch option {
        case .showOriginalPoints:
            cell.accessoryType = viewSettings.pointVisibility == .originalEvents ? .checkmark : .none
        case .showSavitzkyGolayPoints:
            cell.accessoryType = viewSettings.pointVisibility == .savitzkeyGolay ? .checkmark : .none
        case .showDouglasPeuckerPoints:
            cell.accessoryType = viewSettings.pointVisibility == .douglasPeuker ? .checkmark : .none
        case .showOriginalLines:
            cell.accessoryType = viewSettings.lineVisiblity == .originalEvents ? .checkmark : .none
        case .showSavitzkyGolayLines:
            cell.accessoryType = viewSettings.lineVisiblity == .savitzkeyGolay ? .checkmark : .none
        case .showDouglasPeuckerLines:
            cell.accessoryType = viewSettings.lineVisiblity == .douglasPeuker ? .checkmark : .none
        case .showOriginalCurves:
            cell.accessoryType = viewSettings.curveVisibility == .originalEvents ? .checkmark : .none
        case .showSavitzkyGolayCurves:
            cell.accessoryType = viewSettings.curveVisibility == .savitzkeyGolay ? .checkmark : .none
        case .showDouglasPeuckerCurves:
            cell.accessoryType = viewSettings.curveVisibility == .douglasPeuker ? .checkmark : .none
        case .smoothSavitzkyGolay:
            cell.accessoryType = savitzkyGolayEnabled ? .checkmark : .none
        case .smoothDouglasPeucker:
            cell.accessoryType = douglasPeuckerEnabled ? .checkmark : .none
        case .sizeToFit:
            if let settingsDelegate = settingsDelegate,
               settingsDelegate.isFitToSize {
                content.text = "Original Size"
            }
            cell.accessoryType = .none
        case .importEvents, .exportEvents, .clearScreen:
            cell.accessoryType = .none
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
            settingsDelegate?.visibilityChanged(viewSettings)
        }
        func smoothingChanged() {
            settingsDelegate?.smoothingChanged(savitzkyGolayEnabled: savitzkyGolayEnabled,
                                               douglasPeuckerEnabled: douglasPeuckerEnabled)
        }

        switch option {
        case .showOriginalPoints:
            viewSettings.pointVisibility = (viewSettings.pointVisibility == .originalEvents) ? .none : .originalEvents
            visibilityChanged()
        case .showSavitzkyGolayPoints:
            viewSettings.pointVisibility = (viewSettings.pointVisibility == .savitzkeyGolay) ? .none : .savitzkeyGolay
            visibilityChanged()
        case .showDouglasPeuckerPoints:
            viewSettings.pointVisibility = (viewSettings.pointVisibility == .douglasPeuker) ? .none : .douglasPeuker
            visibilityChanged()
        case .showOriginalLines:
            viewSettings.lineVisiblity = (viewSettings.lineVisiblity == .originalEvents) ? .none : .originalEvents
            visibilityChanged()
        case .showSavitzkyGolayLines:
            viewSettings.lineVisiblity = (viewSettings.lineVisiblity == .savitzkeyGolay) ? .none : .savitzkeyGolay
            visibilityChanged()
        case .showDouglasPeuckerLines:
            viewSettings.lineVisiblity = (viewSettings.lineVisiblity == .douglasPeuker) ? .none : .douglasPeuker
            visibilityChanged()
        case .showOriginalCurves:
            viewSettings.curveVisibility = (viewSettings.curveVisibility == .originalEvents) ? .none : .originalEvents
            visibilityChanged()
        case .showSavitzkyGolayCurves:
            viewSettings.curveVisibility = (viewSettings.curveVisibility == .savitzkeyGolay) ? .none : .savitzkeyGolay
            visibilityChanged()
        case .showDouglasPeuckerCurves:
            viewSettings.curveVisibility = (viewSettings.curveVisibility == .douglasPeuker) ? .none : .douglasPeuker
            visibilityChanged()
        case .smoothSavitzkyGolay:
            savitzkyGolayEnabled = !savitzkyGolayEnabled
            smoothingChanged()
        case .smoothDouglasPeucker:
            douglasPeuckerEnabled = !douglasPeuckerEnabled
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

        tableView.reloadRows(in: indexPath.section, with: .automatic)
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
