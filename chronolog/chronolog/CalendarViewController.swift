import UIKit
import EventKit
import CalendarKit
import FirebaseFirestore
import FirebaseAuth

extension Date {
    /// Returns true if the absolute difference between the receiver and another date is less than tolerance.
    func isApproximatelyEqual(to other: Date, tolerance: TimeInterval = 1) -> Bool {
        return abs(self.timeIntervalSince(other)) < tolerance
    }
}

class CalendarViewController: DayViewController, UITabBarControllerDelegate {
    
    let db = Firestore.firestore()
    let userID = Auth.auth().currentUser?.uid
    var customEvents = [CustomEvent]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Add an observer to modify event views after they're created
        NotificationCenter.default.addObserver(self, selector: #selector(hideHandlesInEventViews), name: UIApplication.didBecomeActiveNotification, object: nil)
            
        // Also call it immediately
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.hideHandlesInEventViews()
        }
        
        title = "Calendar"
        self.tabBarController?.delegate = self
        
        dayView.autoScrollToFirstEvent = true
        
        // Configure navigation bar appearance
        if let navigationController = navigationController {
            navigationController.navigationBar.setBackgroundImage(UIImage(), for: .default)
            navigationController.navigationBar.shadowImage = UIImage()
            navigationController.navigationBar.backgroundColor = .white
            navigationController.navigationBar.isTranslucent = false
            
            // Ensure navigation bar items are visible
            navigationController.navigationBar.tintColor = .label
            navigationController.navigationBar.titleTextAttributes = [
                NSAttributedString.Key.foregroundColor: UIColor.label
            ]
        }
        
        // Configure calendar background
        view.backgroundColor = .systemBackground
        
        // Configure calendar settings
        dayView.backgroundColor = .white
        
        fetchEvents { [weak self] events in
            self?.customEvents = events
            self?.reloadData()
        }
        
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        hideHandlesInEventViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Refresh data whenever view appears
        fetchEvents { [weak self] events in
            self?.customEvents = events
            self?.reloadData()
        }
    }
    
    @objc func hideHandlesInEventViews() {
        // Find event views in the hierarchy
        findEventViews(in: dayView)
    }

    func findEventViews(in view: UIView) {
        // Look for EventView class or something containing "handle" in subviews
        for subview in view.subviews {
            if String(describing: type(of: subview)).contains("EventView") {
                hideHandles(in: subview)
            } else if String(describing: type(of: subview)).contains("Handle") {
                subview.isHidden = true
            }
            // Recursively check subviews
            findEventViews(in: subview)
        }
    }

    func hideHandles(in eventView: UIView) {
        // Look for handle-like views (circles or small views at the edges)
        for subview in eventView.subviews {
            let className = String(describing: type(of: subview))
            
            // Look for potential handle views
            if className.contains("Handle") ||
               (subview.frame.width < 20 && subview.frame.height < 20) ||
               subview is UIControl {
                print("Hiding potential handle: \(subview)")
                subview.isHidden = true
            }
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    
    func fetchEvents(completion: @escaping ([CustomEvent]) -> Void) {
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
            for document in querySnapshot!.documents {
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
                
                print("Fetched event: \(title) from \(String(describing: startTime)) to \(String(describing: endTime))")
            }
            completion(events)
        }
    }
    
    override func eventsForDate(_ date: Date) -> [EventDescriptor] {
        var eventDescriptors = [EventDescriptor]()
        let calendar = Calendar.current
        
        for event in customEvents {
            if event.isRecurring {
                let dayIndex = calendar.component(.weekday, from: date) - 1
                let dayName = calendar.weekdaySymbols[dayIndex]
                if let daysOfWeek = event.daysOfWeek,
                   daysOfWeek[dayName, default: false] {
                    createEventDescriptor(for: event, on: date, appendingTo: &eventDescriptors)
                }
            } else {
                if let eventStartTime = event.startTime {
                    if calendar.isDate(eventStartTime, inSameDayAs: date) {
                        createEventDescriptor(for: event, on: date, appendingTo: &eventDescriptors)
                    }
                } else if let eventDate = event.date {
                    if calendar.isDate(eventDate, inSameDayAs: date) {
                        createEventDescriptor(for: event, on: date, appendingTo: &eventDescriptors)
                    }
                }
            }
        }
        
        // Sort descriptors by start time
        eventDescriptors.sort { $0.dateInterval.start < $1.dateInterval.start }
        
        // Apply more aggressive normalization to prevent horizontal stacking
        normalizeEventDescriptors(&eventDescriptors, tolerance: 60) // Use 60 seconds tolerance
        
        // Mark each event as "non-overlapping" by setting editedEvent
        for descriptor in eventDescriptors {
            if let event = descriptor as? Event {
                event.editedEvent = event // This signals to CalendarKit that the event is in its final form
            }
        }
        
        for descriptor in eventDescriptors {
            print("Event: \(descriptor.text) from \(descriptor.dateInterval.start) to \(descriptor.dateInterval.end)")
        }
        
        return eventDescriptors
    }
    
    private func createEventDescriptor(for event: CustomEvent, on date: Date, appendingTo eventDescriptors: inout [EventDescriptor]) {
        let eventDescriptor = Event()
        let descriptionText = event.description.first ?? ""
        eventDescriptor.text = event.title + (descriptionText.isEmpty ? "" : "\n\(descriptionText)")
        eventDescriptor.isAllDay = event.isAllDay
        
        if event.isAllDay {
            let midnight = Calendar.current.startOfDay(for: date)
            guard let nextMidnight = Calendar.current.date(byAdding: .day, value: 1, to: midnight) else { return }
            eventDescriptor.dateInterval = DateInterval(start: midnight, end: nextMidnight)
            eventDescriptor.backgroundColor = UIColor(hex: "#C87501")
        } else {
            // Handle timed events
            guard let startTime = event.startTime ?? event.date else { return }
            var endTime: Date
            
            if let explicitEndTime = event.endTime {
                // For display purposes only: ensure minimum visual duration
                if startTime.isApproximatelyEqual(to: explicitEndTime, tolerance: 1) {
                    // If start and end times are the same, add a small duration (15 minutes)
                    // just for the visual display in CalendarKit
                    endTime = startTime.addingTimeInterval(15 * 60)
                } else {
                    endTime = explicitEndTime.addingTimeInterval(-3)
                }
            } else {
                // If no explicit end time, use duration or default to 15 minutes
                let durationSeconds = Double(event.duration)
                if durationSeconds <= 0 {
                    // Apply a minimum duration for display if duration is zero
                    endTime = startTime.addingTimeInterval(15 * 60 - 3)
                } else {
                    endTime = startTime.addingTimeInterval(durationSeconds - 3)
                }
            }
            
            eventDescriptor.dateInterval = DateInterval(start: startTime, end: endTime)
            
            // Force orange color for regular events
            eventDescriptor.backgroundColor = .systemOrange
        }
        
        // Extra configurations to help prevent dots and ensure color
        eventDescriptor.textColor = .white
        eventDescriptor.editedEvent = eventDescriptor
        
        eventDescriptors.append(eventDescriptor)
    }
    
    /// Adjusts the start/end times of event descriptors to prevent horizontal stacking
    private func normalizeEventDescriptors(_ descriptors: inout [EventDescriptor], tolerance: TimeInterval) {
        guard descriptors.count > 1 else { return }
        let epsilon: TimeInterval = 5 // 5 seconds gap between events
        
        for i in 1..<descriptors.count {
            let previous = descriptors[i - 1]
            let current = descriptors[i]
            
            // If previous event's end is nearly equal to current event's start...
            if previous.dateInterval.end.isApproximatelyEqual(to: current.dateInterval.start, tolerance: tolerance) {
                // Create a more significant gap between events
                let adjustedPreviousEnd = previous.dateInterval.end.addingTimeInterval(-epsilon)
                let currentDuration = current.dateInterval.end.timeIntervalSince(current.dateInterval.start)
                
                // Update the previous event's interval
                previous.dateInterval = DateInterval(
                    start: previous.dateInterval.start,
                    end: adjustedPreviousEnd
                )
                
                // Set the current event to start after the gap
                let newStart = adjustedPreviousEnd.addingTimeInterval(epsilon)
                let newEnd = newStart.addingTimeInterval(currentDuration)
                current.dateInterval = DateInterval(start: newStart, end: newEnd)
            }
        }
    }
    
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if viewController is CalendarViewController {
            fetchEvents { [weak self] events in
                self?.customEvents = events
                self?.reloadData()
            }
        }
    }
    
    func formatEventDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) / 60 % 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    override func dayViewDidSelectEventView(_ eventView: EventView) {
        guard let selectedEventDescriptor = eventView.descriptor as? Event else {
            return
        }
    
        let matchingEvent = customEvents.first { event in
            if event.isAllDay {
                // For all-day events, match based on date and title
                if let eventDate = event.date {
                    let isSameDay = Calendar.current.isDate(eventDate, inSameDayAs: selectedEventDescriptor.dateInterval.start)
                    return isSameDay && selectedEventDescriptor.text.contains(event.title)
                }
                return false
            } else {
                // For regular events, match based on start time and title
                // We prioritize matching the start time since end times may have been adjusted for display
                if let eventStart = event.startTime ?? event.date {
                    return eventStart.isApproximatelyEqual(to: selectedEventDescriptor.dateInterval.start, tolerance: 10) &&
                           selectedEventDescriptor.text.contains(event.title)
                }
                return false
            }
        }
        
        if let event = matchingEvent {
            showEventDetails(for: event)
        }
    }
    
    // Add handler for all-day events specifically
    override func dayViewDidLongPressEventView(_ eventView: EventView) {
        // Handle the event selection the same way as regular events
        dayViewDidSelectEventView(eventView)
    }
    
    
        
    private func showEventDetails(for event: CustomEvent) {
        let alert = UIAlertController(title: event.title, message: nil, preferredStyle: .alert)
        
        let dateFormatter = DateFormatter()
        
        var details = [String]()
        
        if event.isAllDay {
            // For all-day events, only show the date without time
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .none
            if let date = event.date {
                details.append("Date: \(dateFormatter.string(from: date))")
            }
            details.append("All Day Event")
        } else {
            // For regular events, show date and time
            dateFormatter.dateStyle = .medium
            dateFormatter.timeStyle = .short
            if let start = event.startTime {
                details.append("Starts: \(dateFormatter.string(from: start))")
            }
            if let end = event.endTime {
                details.append("Ends: \(dateFormatter.string(from: end))")
            }
            
            // Handle duration display
            if let durationValue: Int? = event.duration {
                let hours = durationValue! / 3600
                let minutes = (durationValue! % 3600) / 60
                if hours > 0 {
                    details.append("Duration: \(hours)h \(minutes)m")
                } else {
                    details.append("Duration: \(minutes)m")
                }
            }
        }
        
        if let deadline = event.deadline {
            details.append("Deadline: \(dateFormatter.string(from: deadline))")
        }
        
        details.append("Priority: \(event.priority.rawValue.capitalized)")
        
        // Add notes without duplicating them
        if let firstNote = event.description.first, !firstNote.isEmpty {
            details.append("Notes: \(firstNote)")
        }
        
        let settingsInfo = [
                event.allowSplit ? "Splitting Allowed" : nil,
                event.allowOverlap ? "Overlapping Allowed" : nil
        ].compactMap { $0 }
        
        if !settingsInfo.isEmpty {
            details.append("Settings: \(settingsInfo.joined(separator: ", "))")
        }
        
        // Create attributed string with left alignment
        let attributedString = NSMutableAttributedString(string: details.joined(separator: "\n"))
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .left
        
        let attributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle,
            .font: UIFont.systemFont(ofSize: 14)
        ]
        
        attributedString.addAttributes(attributes, range: NSRange(location: 0, length: attributedString.length))
        
        // Set the attributed message
        alert.setValue(attributedString, forKey: "attributedMessage")
        
        alert.addAction(UIAlertAction(title: "Close", style: .default))
        
        present(alert, animated: true)
    }
}


// Add UIColor extension for hex color support if not already present
extension UIColor {
    convenience init(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexString = hexString.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgb)
        
        let red = CGFloat((rgb & 0xFF0000) >> 16) / 255.0
        let green = CGFloat((rgb & 0x00FF00) >> 8) / 255.0
        let blue = CGFloat(rgb & 0x0000FF) / 255.0
        
        self.init(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
