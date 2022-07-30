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
    private var currentEventIndex = -1
    var allEvents: [DrawEvent] = []

    private var playButton: UIBarButtonItem!
    private var displayLink: CADisplayLink!

    init() {
        super.init(style: .grouped)
        finishSetup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        finishSetup()
    }

    private func finishSetup() {
        displayLink = CADisplayLink(target: self, selector: #selector(nextEvent))
        displayLink.preferredFrameRateRange = CAFrameRateRange(minimum: 30, maximum: 30)
        displayLink.isPaused = true
        displayLink.add(to: .main, forMode: .default)

        AppDelegate.shared.inkModel.touchEventStream.addConsumer({ (updatedEvents) in
            if self.currentEventIndex >= self.allEvents.count - 1 {
                self.allEvents.append(contentsOf: updatedEvents)
                self.currentEventIndex = self.allEvents.count - 1
            }
            self.scheduleReload()
        }, reset: {})
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        let rewind = UIBarButtonItem(image: UIImage(systemName: "backward.end.alt"),
                                     style: .plain,
                                     target: self,
                                     action: #selector(rewind))
        let prevButton = UIBarButtonItem(image: UIImage(systemName: "backward.frame"),
                                         style: .plain,
                                         target: self,
                                         action: #selector(prevEvent))
        playButton = UIBarButtonItem(image: UIImage(systemName: "play"),
                                     style: .plain,
                                     target: self,
                                     action: #selector(play))
        let nextButton = UIBarButtonItem(image: UIImage(systemName: "forward.frame"),
                                         style: .plain,
                                         target: self,
                                         action: #selector(nextEvent))
        let fastforward = UIBarButtonItem(image: UIImage(systemName: "forward.end.alt"),
                                          style: .plain,
                                          target: self,
                                          action: #selector(fastforward))
        let flex1 = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let flex2 = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)

        self.toolbarItems = [flex1, rewind, prevButton, playButton, nextButton, fastforward, flex2]
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scrollToCurrentRow(animated: false)
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

    @objc func play() {
        if displayLink.isPaused {
            displayLink.isPaused = false
            playButton.image = UIImage(systemName: "pause")
        } else {
            displayLink.isPaused = true
            playButton.image = UIImage(systemName: "play")
        }
    }

    @objc func nextEvent() {
        if currentEventIndex < allEvents.count - 1 {
            let event = allEvents[currentEventIndex + 1]
            AppDelegate.shared.inkModel.touchEventStream.process(events: [event])
            currentEventIndex += 1
            scheduleReload()
        } else {
            displayLink.isPaused = true
            playButton.image = UIImage(systemName: "play")
        }
    }

    @objc func fastforward() {
        replayEvents(through: allEvents.count - 1)
    }

    func replayEvents(through index: Int = -1) {
        let events = allEvents
        if index <= currentEventIndex {
            allEvents = []
            AppDelegate.shared.inkModel.touchEventStream.reset()
            currentEventIndex = -1
            if index == -1 || index >= events.count {
                AppDelegate.shared.inkModel.touchEventStream.process(events: events)
            } else {
                allEvents = events
                if !allEvents.isEmpty {
                    let toProcess = Array(allEvents[0...index])
                    AppDelegate.shared.inkModel.touchEventStream.process(events: toProcess)
                }
                currentEventIndex = index
            }
        } else if index < allEvents.count,
                  case let toProcess = Array(allEvents[currentEventIndex + 1...index]),
                  !toProcess.isEmpty {
            AppDelegate.shared.inkModel.touchEventStream.process(events: toProcess)
            currentEventIndex = index
        }
        // we don't need to reload the table explicitly here, since the event list is unchanged
    }

    func reset() {
        currentEventIndex = -1
        allEvents = []
        AppDelegate.shared.inkModel.touchEventStream.reset()
        reloadTable()
    }

    func importEvents(_ events: [DrawEvent]) {
        // get up to date before our import
        replayEvents(through: allEvents.count - 1)
        let existingIdentifiers = allEvents.map({ $0.identifier })
        let filtered = events.filter({ !existingIdentifiers.contains($0.identifier) })
        AppDelegate.shared.inkModel.touchEventStream.process(events: filtered)
    }

    // MARK: - Reload
    private var timer: Timer?
    private func scheduleReload() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(reloadTable), userInfo: nil, repeats: false)
    }

    @objc private func reloadTable() {
        AppDelegate.shared.inkModel.touchEventStream.gesture.isEnabled = currentEventIndex >= allEvents.count - 1
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
        scrollToCurrentRow(animated: true)
    }

    func scrollToCurrentRow(animated: Bool) {
        if currentEventIndex >= 0, currentEventIndex < allEvents.count {
            tableView.scrollToRow(at: IndexPath(row: currentEventIndex, section: 0),
                                  at: .none,
                                  animated: animated)
        }
    }

    // MARK: - UITableView Delegate & DataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentTableCount
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell") else { fatalError() }

        var configuration = cell.defaultContentConfiguration()
        let event = allEvents[indexPath.row]

        if event as? GestureCallbackEvent != nil {
            configuration.text = "Gesture Callback"
            configuration.image = UIImage(systemName: "waveform.circle")
        } else if let touchEvent = event as? TouchEvent {
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
                configuration.textProperties.color = UIColor.isIntial
            } else {
                configuration.text = "single event: " + touchEvent.location.debugDescription
                configuration.textProperties.color = UIColor.isFinal
            }
            let touchId = touchEvent.pointIdentifier.suffix(from: touchEvent.pointIdentifier.firstIndex(of: ":")!)
            configuration.secondaryText = touchEvent.phase.stringValue + " id" + String(touchId)
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
        } else {
            configuration.text = event.identifier
            configuration.image = UIImage(systemName: "questionmark.circle")
        }

        configuration.secondaryText = "\(indexPath.row): " + (configuration.secondaryText ?? "")

        cell.accessoryType = indexPath.row > currentEventIndex ? .none : .checkmark

        cell.contentConfiguration = configuration

        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row < currentEventIndex {
            replayEvents(through: indexPath.row)
        }
        var eventsToProcess: [DrawEvent] = []
        while indexPath.row > currentEventIndex + eventsToProcess.count {
            let nextIndex = currentEventIndex + eventsToProcess.count + 1
            guard nextIndex < allEvents.count else { assertionFailure(); break }
            let event = allEvents[nextIndex]
            eventsToProcess.append(event)
        }
        if !eventsToProcess.isEmpty {
            AppDelegate.shared.inkModel.touchEventStream.process(events: eventsToProcess)
        }
        currentEventIndex += eventsToProcess.count
        reloadTable()
    }
}
