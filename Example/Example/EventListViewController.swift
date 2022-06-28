//
//  EventListViewController.swift
//  Example
//
//  Created by Adam Wulf on 6/27/22.
//

import Foundation
import UIKit
import Inkable

class EventListViewController: UITableViewController {
    private var currentTableCount = 0
    var allEvents: [DrawEvent] = []
    let touchEventStream = TouchEventStream()

    weak var inkViewController: InkViewController?

    init() {
        super.init(style: .grouped)
        finishSetup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        finishSetup()
    }

    private func finishSetup() {
        self.touchEventStream.addConsumer { (updatedEvents) in
            self.allEvents.append(contentsOf: updatedEvents)
            self.scheduleReload()
        }

        let rewind = UIBarButtonItem(image: UIImage(systemName: "backward.end.alt"),
                                         style: .plain,
                                         target: self,
                                         action: #selector(nextEvent))
        let prevButton = UIBarButtonItem(image: UIImage(systemName: "backward.frame"),
                                         style: .plain,
                                         target: self,
                                         action: #selector(nextEvent))
        let playButton = UIBarButtonItem(image: UIImage(systemName: "play"),
                                         style: .plain,
                                         target: self,
                                         action: #selector(nextEvent))
        let nextButton = UIBarButtonItem(image: UIImage(systemName: "forward.frame"),
                                         style: .plain,
                                         target: self,
                                         action: #selector(nextEvent))
        let fastforward = UIBarButtonItem(image: UIImage(systemName: "forward.end.alt"),
                                         style: .plain,
                                         target: self,
                                         action: #selector(nextEvent))

//        self.navigationItem.title = nil
//        self.navigationItem.leftBarButtonItems = [fastforward, nextButton, playButton, prevButton, rewind]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
    }

    // MARK: - Actions

    @objc func nextEvent() {

    }

    func replayEvents() {
        let events = allEvents
        allEvents = []
        touchEventStream.reset()
        inkViewController?.reset()
        touchEventStream.process(events: events)
        // we don't need to reload the table explicitly here, since the event list is unchanged
    }

    func reset() {
        allEvents = []
        touchEventStream.reset()
        inkViewController?.reset()
        reloadTable()
    }

    func importEvents(_ events: [DrawEvent]) {
        let existingIdentifiers = allEvents.map({ $0.identifier })
        let filtered = events.filter({ !existingIdentifiers.contains($0.identifier) })
        allEvents += filtered
        touchEventStream.process(events: filtered)
    }

    // MARK: - Reload
    private var timer: Timer?
    private func scheduleReload() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(reloadTable), userInfo: nil, repeats: false)
    }

    @objc private func reloadTable() {
        timer = nil
        tableView.beginUpdates()
        if allEvents.count < currentTableCount {
            let currentIndexes = (0..<allEvents.count).map({ IndexPath(row: $0, section: 0) })
            let removedIndexes = (allEvents.count..<currentTableCount).map({ IndexPath(row: $0, section: 0) })
            tableView.reloadRows(at: currentIndexes, with: .none)
            tableView.deleteRows(at: removedIndexes, with: .automatic)
        } else {
            let currentIndexes = (0..<currentTableCount).map({ IndexPath(row: $0, section: 0) })
            let addedIndexes = (currentTableCount..<allEvents.count).map({ IndexPath(row: $0, section: 0) })
            tableView.reloadRows(at: currentIndexes, with: .none)
            tableView.insertRows(at: addedIndexes, with: .automatic)
        }
        currentTableCount = allEvents.count
        tableView.endUpdates()
    }

    // MARK: - UITableView Delegate & DataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentTableCount
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell") else { fatalError() }

        var configuration = cell.defaultContentConfiguration()
        let event = allEvents[indexPath.row]

        if let touchEvent = event as? TouchEvent {
            if touchEvent.isPrediction {
                configuration.text = "prediction: " + touchEvent.location.debugDescription
                configuration.textProperties.color = UIColor.isPrediction
            } else if touchEvent.isUpdate {
                if touchEvent.estimatedProperties.isEmpty {
                    configuration.text = "final update: " + touchEvent.location.debugDescription
                    configuration.textProperties.color = UIColor.isFinal
                } else {
                    configuration.text = "update: " + touchEvent.location.debugDescription
                    configuration.textProperties.color = UIColor.isUpdate
                }
            } else if touchEvent.expectsUpdate {
                configuration.text = "will update: " + touchEvent.location.debugDescription
                configuration.textProperties.color = UIColor.isUpdate
            } else {
                configuration.text = "final: " + touchEvent.location.debugDescription
                configuration.textProperties.color = UIColor.isFinal
            }
            let touchId = touchEvent.pointIdentifier.suffix(from: touchEvent.pointIdentifier.firstIndex(of: ":")!)
            configuration.secondaryText = String(touchId)
            switch touchEvent.type {
            case .direct:
                configuration.image = UIImage(systemName: "hand.point.up")
            case .indirect:
                configuration.image = UIImage(systemName: "rectangle.and.hand.point.up.left.filled")
            case .pencil:
                configuration.image = UIImage(systemName: "pencil.circle")
            case .indirectPointer:
                configuration.image = UIImage(systemName: "square.and.pencil")
            @unknown default:
                configuration.image = UIImage(systemName: "questionmark.circle")
            }
        } else if let touchEvent = event as? ToolEvent {
            configuration.text = "Tool: \(touchEvent.style.width)pt \(touchEvent.style.color?.debugDescription ?? "clear")"
            configuration.image = UIImage(systemName: "paintbrush")
        } else {
            configuration.text = event.identifier
            configuration.image = UIImage(systemName: "questionmark.circle")
        }

        cell.contentConfiguration = configuration

        return cell
    }
}
