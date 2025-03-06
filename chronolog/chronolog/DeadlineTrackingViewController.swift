//
//  DeadlineTrackingViewController.swift
//  chronolog
//
//  Created by Janie Giron on 3/3/25.
//

import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth

class DeadlineTrackingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Properties
    
    private var tableView: UITableView!
    private let db = Firestore.firestore()
    let userID = Auth.auth().currentUser?.uid
    var events = [CustomEvent]()
    
    // MARK: - Lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        fetchEventsWithDeadlines()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Refresh data when view appears
        fetchEventsWithDeadlines()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        // Set title for navigation bar
        title = "Deadlines"
        
        // Create table view
        tableView = UITableView(frame: view.bounds, style: .insetGrouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "EventCell")
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(tableView)
        
        // Add refresh control
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshData), for: .valueChanged)
        tableView.refreshControl = refreshControl
    }
    
    @objc private func refreshData() {
        fetchEventsWithDeadlines()
        tableView.refreshControl?.endRefreshing()
    }
    
    // MARK: - Data Fetching
    
    private func fetchEventsWithDeadlines() {
        guard let userID = userID else {
            print("No user ID found")
            // Show empty state
            self.events = []
            self.tableView.reloadData()
            return
        }
        
        // First fetch all events using your existing method
        fetchEvents { [weak self] allEvents in
            guard let self = self else { return }
            
            // Filter events that have a deadline
            let eventsWithDeadlines = allEvents.filter { $0.deadline != nil }
            
            // Sort by deadline (closest first)
            let sortedEvents = eventsWithDeadlines.sorted {
                ($0.deadline ?? Date.distantFuture) < ($1.deadline ?? Date.distantFuture)
            }
            
            // Update UI
            self.events = sortedEvents
            
            // Debug prints
            print("Total events: \(allEvents.count)")
            print("Events with deadlines: \(eventsWithDeadlines.count)")
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    private func fetchEvents(completion: @escaping ([CustomEvent]) -> Void) {
        guard let userID = userID else {
            completion([])
            return
        }
        
        db.collection("userEvents").document(userID).collection("events").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error fetching documents: \(error)")
                completion([])
                return
            }
            
            var events = [CustomEvent]()
            for document in querySnapshot?.documents ?? [] {
                let data = document.data()
                
                // Extract and unwrap all values
                let title = data["title"] as? String ?? "No Title"
                let startTimestamp = data["startTime"] as? Timestamp
                let endTimestamp = data["endTime"] as? Timestamp
                let dateTimestamp = data["date"] as? Timestamp
                let duration = data["duration"] as? Int ?? 0  // Provide default value
                let isRecurring = data["isRecurring"] as? Bool ?? false
                let daysOfWeek = data["daysOfWeek"] as? [String: Bool]
                let isAllDay = data["isAllDay"] as? Bool ?? false
                let allowSplit = data["allowSplit"] as? Bool ?? false
                let allowOverlap = data["allowOverlap"] as? Bool ?? false
                let deadlineTimestamp = data["deadline"] as? Timestamp
                
                // Handle priority conversion
                let priorityString = data["priority"] as? String ?? "medium"
                let priority: CustomEvent.Priority = {
                    switch priorityString.lowercased() {
                    case "high": return .high
                    case "low": return .low
                    default: return .medium
                    }
                }()
                
                let startTime = startTimestamp?.dateValue()
                let endTime = endTimestamp?.dateValue()
                let deadline = deadlineTimestamp?.dateValue()
                let date = dateTimestamp?.dateValue()
                let description = data["description"] as? String ?? ""
                
                let event = CustomEvent(
                    title: title,
                    date: date ?? startTime ?? Date(),  // Provide a default value
                    startTime: startTime,
                    endTime: endTime,
                    duration: duration,  // Already has default value
                    description: [description],  // Wrap in array
                    isRecurring: isRecurring,
                    daysOfWeek: daysOfWeek,
                    isAllDay: isAllDay,
                    allowSplit: allowSplit,
                    allowOverlap: allowOverlap,
                    priority: priority,
                    deadline: deadline
                )
                events.append(event)
                
                print("Fetched event: \(title) with deadline: \(String(describing: deadline))")
            }
            completion(events)
        }
    }
    
    // MARK: - UITableViewDataSource
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if events.isEmpty {
            tableView.setEmptyMessage("No upcoming deadlines")
            return 0
        } else {
            tableView.restore()
            return events.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EventCell", for: indexPath)
        
        let event = events[indexPath.row]
        
        // Configure cell
        var content = cell.defaultContentConfiguration()
        content.text = event.title
        
        // Format deadline date for display
        if let deadline = event.deadline {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            content.secondaryText = "Due: \(formatter.string(from: deadline)) • Priority: \(event.priority.rawValue)"
        } else {
            content.secondaryText = "Priority: \(event.priority.rawValue)"
        }
        
        // Color code based on priority
        switch event.priority {
        case .high:
            content.secondaryTextProperties.color = .systemRed
        case .medium:
            content.secondaryTextProperties.color = .systemOrange
        case .low:
            content.secondaryTextProperties.color = .systemBlue
        }
        
        cell.contentConfiguration = content
        cell.accessoryType = .disclosureIndicator
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Upcoming Deadlines"
    }
    
    // MARK: - UITableViewDelegate
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        // Get the selected event
        let selectedEvent = events[indexPath.row]
        
        // Navigate to event detail screen
        showEventDetails(selectedEvent)
    }
    
    // MARK: - Navigation
    
    private func showEventDetails(_ event: CustomEvent) {
        // Create an event detail view controller
        let detailVC = EventDetailViewController(event: event)
        
        // Push to navigation stack
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    // MARK: - Deletion Methods

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Remove from local array
            events.remove(at: indexPath.row)
            
            // Update the UI
            tableView.deleteRows(at: [indexPath], with: .fade)
            
            // If we have no events left, show the empty message
            if events.isEmpty {
                tableView.setEmptyMessage("No upcoming deadlines")
            }
        }
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        // Create swipe action
        let deleteAction = UIContextualAction(style: .destructive, title: "Delete") { [weak self] (action, view, completion) in
            guard let self = self else {
                completion(false)
                return
            }
            
            // Show confirmation alert
            let alert = UIAlertController(
                title: "Delete Deadline",
                message: "Are you sure you want to delete this deadline from the list?",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in
                completion(false)
            })
            
            alert.addAction(UIAlertAction(title: "Delete", style: .destructive) { _ in
                // Remove from local array
                self.events.remove(at: indexPath.row)
                
                // Update the UI
                self.tableView.deleteRows(at: [indexPath], with: .fade)
                
                // If we have no events left, show the empty message
                if self.events.isEmpty {
                    self.tableView.setEmptyMessage("No upcoming deadlines")
                }
                
                completion(true)
            })
            
            self.present(alert, animated: true)
        }
        
        // Configure swipe action
        deleteAction.backgroundColor = .systemRed
        
        // Create and return swipe actions configuration
        let configuration = UISwipeActionsConfiguration(actions: [deleteAction])
        configuration.performsFirstActionWithFullSwipe = false
        return configuration
    }
}

// MARK: - Empty Table View Extension

extension UITableView {
    func setEmptyMessage(_ message: String) {
        let messageLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height))
        messageLabel.text = message
        messageLabel.textColor = .secondaryLabel
        messageLabel.numberOfLines = 0
        messageLabel.textAlignment = .center
        messageLabel.font = UIFont.systemFont(ofSize: 16)
        messageLabel.sizeToFit()
        
        self.backgroundView = messageLabel
    }
    
    func restore() {
        self.backgroundView = nil
    }
}

// MARK: - Event Detail View Controller

class EventDetailViewController: UIViewController {
    
    // MARK: - Properties
    
    private let event: CustomEvent
    private let scrollView = UIScrollView()
    private let contentView = UIView()
    
    // MARK: - Initialization
    
    init(event: CustomEvent) {
        self.event = event
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        title = "Event Details"
        view.backgroundColor = .systemBackground
        
        // Setup scroll view
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            
            contentView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        
        // Create stack view for content
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stackView)
        
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 16),
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16)
        ])
        
        // Title
        let titleLabel = createHeaderLabel(text: event.title)
        stackView.addArrangedSubview(titleLabel)
        
        // Priority
        let priorityView = createInfoRow(label: "Priority:", detail: event.priority.rawValue)
        stackView.addArrangedSubview(priorityView)
        
        // Deadline
        if let deadline = event.deadline {
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            formatter.timeStyle = .short
            let deadlineView = createInfoRow(label: "Deadline:", detail: formatter.string(from: deadline))
            stackView.addArrangedSubview(deadlineView)
        }
        
        // Date
        if let date = event.date {
            let formatter = DateFormatter()
            formatter.dateStyle = .long
            let dateView = createInfoRow(label: "Date:", detail: formatter.string(from: date))
            stackView.addArrangedSubview(dateView)
        }
        
        // Time
        if let start = event.startTime, let end = event.endTime {
            let formatter = DateFormatter()
            formatter.timeStyle = .short
            let timeView = createInfoRow(
                label: "Time:",
                detail: "\(formatter.string(from: start)) - \(formatter.string(from: end))"
            )
            stackView.addArrangedSubview(timeView)
        }
        
        // Duration
        let durationView = createInfoRow(label: "Duration:", detail: "\(event.duration) minutes")
        stackView.addArrangedSubview(durationView)
        
        // All day
        let allDayView = createInfoRow(label: "All Day:", detail: event.isAllDay ? "Yes" : "No")
        stackView.addArrangedSubview(allDayView)
        
        // Recurring
        let recurringView = createInfoRow(label: "Recurring:", detail: event.isRecurring ? "Yes" : "No")
        stackView.addArrangedSubview(recurringView)
        
        // Days of week (if recurring)
        if event.isRecurring, let days = event.daysOfWeek {
            let daysString = days.filter { $0.value }.map { $0.key }.joined(separator: ", ")
            if !daysString.isEmpty {
                let daysView = createInfoRow(label: "Repeats on:", detail: daysString)
                stackView.addArrangedSubview(daysView)
            }
        }
        
        // Description
        if !event.description.isEmpty {
            let descriptionHeader = createSectionHeader(text: "Description")
            stackView.addArrangedSubview(descriptionHeader)
            
            for item in event.description {
                let itemLabel = UILabel()
                itemLabel.text = "• \(item)"
                itemLabel.numberOfLines = 0
                itemLabel.textColor = .label
                stackView.addArrangedSubview(itemLabel)
            }
        }
    }
    
    // MARK: - Helper methods for UI
    
    private func createHeaderLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.boldSystemFont(ofSize: 22)
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }
    
    private func createSectionHeader(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.textColor = .secondaryLabel
        return label
    }
    
    private func createInfoRow(label: String, detail: String) -> UIView {
        let container = UIView()
        
        let labelView = UILabel()
        labelView.text = label
        labelView.font = UIFont.boldSystemFont(ofSize: 16)
        labelView.translatesAutoresizingMaskIntoConstraints = false
        
        let detailView = UILabel()
        detailView.text = detail
        detailView.numberOfLines = 0
        detailView.translatesAutoresizingMaskIntoConstraints = false
        
        container.addSubview(labelView)
        container.addSubview(detailView)
        
        NSLayoutConstraint.activate([
            labelView.topAnchor.constraint(equalTo: container.topAnchor, constant: 4),
            labelView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            labelView.widthAnchor.constraint(equalToConstant: 100),
            
            detailView.topAnchor.constraint(equalTo: container.topAnchor, constant: 4),
            detailView.leadingAnchor.constraint(equalTo: labelView.trailingAnchor, constant: 8),
            detailView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            detailView.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -4)
        ])
        
        return container
    }
}
