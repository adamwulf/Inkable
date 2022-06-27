//
//  BaseViewController.swift
//  DrawUIExample
//
//  Created by Adam Wulf on 3/14/21.
//

import UIKit
import Inkable
import UniformTypeIdentifiers

class BaseViewController: UIViewController, UIDocumentPickerDelegate {

    var allEvents: [DrawEvent] = []

    let touchEventStream = TouchEventStream()

    required init?(coder: NSCoder) {
        super.init(coder: coder)

        touchEventStream.addConsumer { (updatedEvents) in
            self.allEvents.append(contentsOf: updatedEvents)
        }
    }

    func reset() {
        allEvents = []
        touchEventStream.reset()
    }
}

extension BaseViewController {

    @objc func didRequestExport(_ sender: UIView) {
        let tmpDirURL = FileManager.default.temporaryDirectory.appendingPathComponent("events").appendingPathExtension("json")
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = [.withoutEscapingSlashes, .prettyPrinted]

        if let json = try? jsonEncoder.encode(allEvents) {
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

    @objc func didRequestImport(_ sender: UIView) {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: [UTType.json, UTType.text])
        picker.delegate = self
        present(picker, animated: true, completion: nil)
    }

    @objc func didRequestClear(_ sender: UIView) {
        reset()
    }
}
