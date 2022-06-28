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
    private var currentEventIndex = 0
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
            if self.currentEventIndex >= self.allEvents.count - 1 {
                self.allEvents.append(contentsOf: updatedEvents)
                self.currentEventIndex = self.allEvents.count - 1
            }
            self.scheduleReload()
        }

        let rewind = UIBarButtonItem(image: UIImage(systemName: "backward.end.alt"),
                                         style: .plain,
                                         target: self,
                                         action: #selector(rewind))
        let prevButton = UIBarButtonItem(image: UIImage(systemName: "backward.frame"),
                                         style: .plain,
                                         target: self,
                                         action: #selector(prevEvent))
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
                                         action: #selector(fastforward))

        self.navigationItem.title = nil
        self.navigationItem.leftBarButtonItems = [rewind, prevButton, playButton, nextButton, fastforward]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
    }

    // MARK: - Actions

    @objc func rewind() {
        replayEvents(through: 0)
    }

    @objc func prevEvent() {
        if currentEventIndex > 0 {
            replayEvents(through: currentEventIndex - 1)
        }
    }

    @objc func nextEvent() {
        if currentEventIndex < allEvents.count - 1 {
            let event = allEvents[currentEventIndex + 1]
            touchEventStream.process(events: [event])
            currentEventIndex += 1
            reloadTable()
        }
    }

    @objc func fastforward() {
        replayEvents(through: allEvents.count - 1)
    }

    func replayEvents(through index: Int = -1) {
        let events = allEvents
        allEvents = []
        touchEventStream.reset()
        inkViewController?.reset()
        currentEventIndex = 0
        if index == -1 || index >= events.count {
            touchEventStream.process(events: events)
        } else {
            allEvents = events
            if !allEvents.isEmpty {
                let toProcess = Array(allEvents[0...index])
                touchEventStream.process(events: toProcess)
            }
            currentEventIndex = index
        }
        // we don't need to reload the table explicitly here, since the event list is unchanged
    }

    func reset() {
        currentEventIndex = 0
        currentTableCount = 0
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
        touchEventStream.gesture.isEnabled = currentEventIndex >= allEvents.count - 1
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
            configuration.secondaryText = touchEvent.phase.stringValue + String(touchId)
            configuration.secondaryTextProperties.numberOfLines = 1
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

        cell.accessoryType = indexPath.row > currentEventIndex ? .none : .checkmark

        cell.contentConfiguration = configuration

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row < currentEventIndex {
            replayEvents(through: indexPath.row)
        }
        while indexPath.row > currentEventIndex {
            currentEventIndex += 1
            let event = allEvents[currentEventIndex]
            touchEventStream.process(events: [event])
        }
        reloadTable()
    }
}