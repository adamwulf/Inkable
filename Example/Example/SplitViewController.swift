//
//  SplitViewController.swift
//  Example
//
//  Created by Adam Wulf on 6/25/22.
//

import Foundation
import UIKit
import Inkable

class SplitViewController: UISplitViewController {

    private var settingsViewController: SettingsViewController? {
        guard let nav = self.viewController(for: .supplementary) as? UINavigationController else { return nil }
        return nav.viewControllers.first as? SettingsViewController
    }

    private var inkViewController: InkViewController? {
        return self.viewController(for: .secondary) as? InkViewController
    }

    private var eventListViewController: EventListViewController? {
        guard let nav = self.viewController(for: .primary) as? UINavigationController else { return nil }
        return nav.viewControllers.first as? EventListViewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        settingsViewController?.settingsDelegate = self
        eventListViewController?.inkViewController = inkViewController
        inkViewController?.eventListViewController = eventListViewController
    }
}

extension SplitViewController: SettingsViewControllerDelegate {
    func visibilityChanged(pointsEnabled: Bool, linesEnabled: Bool, curvesEnabled: Bool) {
        inkViewController?.visibilityChanged(pointsEnabled: pointsEnabled, linesEnabled: linesEnabled, curvesEnabled: curvesEnabled)
    }

    func smoothingChanged(savitzkyGolayEnabled: Bool, douglasPeuckerEnabled: Bool) {
        inkViewController?.smoothingChanged(savitzkyGolayEnabled: savitzkyGolayEnabled, douglasPeuckerEnabled: douglasPeuckerEnabled)
        eventListViewController?.replayEvents()
    }

    func clearAllData() {
        eventListViewController?.reset()
        inkViewController?.clearTransform()
    }

    func importEvents(_ events: [DrawEvent]) {
        inkViewController?.clearTransform()
        eventListViewController?.importEvents(events)
    }

    func exportEvents(sender: UIView) {
        guard let allEvents = eventListViewController?.allEvents else { return }
        let touchEvents = allEvents.compactMap({ $0 as? TouchEvent })
        let tmpDirURL = FileManager.default.temporaryDirectory.appendingPathComponent("events").appendingPathExtension("json")
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = [.withoutEscapingSlashes, .prettyPrinted]

        if let json = try? jsonEncoder.encode(touchEvents) {
            do {
                try json.write(to: tmpDirURL)

                let sharevc = UIActivityViewController(activityItems: [tmpDirURL], applicationActivities: nil)
                sharevc.popoverPresentationController?.sourceView = sender
                present(sharevc, animated: true, completion: nil)
            } catch {
                // ignore
            }
        }
    }

    var isFitToSize: Bool {
        return inkViewController?.isFitToSize ?? false
    }

    func toggleSizeToFit() {
        inkViewController?.toggleSizeToFit()
    }
}
