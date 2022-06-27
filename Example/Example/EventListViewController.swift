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
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
    }

    // MARK: - Actions

    func replayEvents() {
        let events = allEvents
        allEvents = []
        touchEventStream.reset()
        inkViewController?.reset()
        touchEventStream.process(events: events)
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

        configuration.text = allEvents[indexPath.row].identifier

        cell.contentConfiguration = configuration

        return cell
    }
}
