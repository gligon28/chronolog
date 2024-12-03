import UIKit
import EventKit
import CalendarKit
import FirebaseFirestore
import FirebaseAuth

class CalendarViewController: DayViewController, UITabBarControllerDelegate {
    
    let db = Firestore.firestore()
    let userID = Auth.auth().currentUser?.uid
    var customEvents = [CustomEvent]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Calendar"
        self.tabBarController?.delegate = self
        
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Refresh data whenever view appears
        fetchEvents { [weak self] events in
            self?.customEvents = events
            self?.reloadData()
        }
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
                    priority: priority
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
                // Handle both startTime and date fields
                if let eventStartTime = event.startTime {
                    if calendar.isDate(eventStartTime, inSameDayAs: date) {
                        createEventDescriptor(for: event, on: date, appendingTo: &eventDescriptors)
                    }
                } else if let eventDate = event.date {  // Changed to proper optional binding
                    if calendar.isDate(eventDate, inSameDayAs: date) {
                        createEventDescriptor(for: event, on: date, appendingTo: &eventDescriptors)
                    }
                }
            }
        }
        
        return eventDescriptors.sorted { event1, event2 in
            if event1.isAllDay && !event2.isAllDay { return true }
            if !event1.isAllDay && event2.isAllDay { return false }
            return event1.dateInterval.start < event2.dateInterval.start
        }
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
            eventDescriptor.backgroundColor = .systemBlue
        } else {
            // Handle timed events
            guard let startTime = event.startTime ?? event.date else { return }
            let endTime: Date
            
            if let explicitEndTime = event.endTime {
                endTime = explicitEndTime
            } else {
                let durationSeconds = Double(event.duration)
                endTime = startTime.addingTimeInterval(durationSeconds)
            }
            
            eventDescriptor.dateInterval = DateInterval(start: startTime, end: endTime)
            eventDescriptor.backgroundColor = .systemOrange
        }
        
        eventDescriptor.textColor = .white
        eventDescriptors.append(eventDescriptor)
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
        
        // Modified matching logic to handle both all-day and regular events
        let matchingEvent = customEvents.first { event in
            if event.isAllDay {
                // For all-day events, match based on date and title
                if let eventDate = event.date {
                    let isSameDay = Calendar.current.isDate(eventDate, inSameDayAs: selectedEventDescriptor.dateInterval.start)
                    return isSameDay && selectedEventDescriptor.text.contains(event.title)
                }
                return false
            } else {
                // For regular events, match based on start/end times and title
                if let eventStart = event.startTime ?? event.date,
                   let eventEnd = event.endTime {
                    return selectedEventDescriptor.dateInterval.start == eventStart &&
                           selectedEventDescriptor.dateInterval.end == eventEnd &&
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
//        dateFormatter.dateStyle = .medium
//        dateFormatter.timeStyle = .short
        
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


