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
                    isAllDay: isAllDay
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
            eventDescriptor.backgroundColor = .systemPurple
        } else {
            // Handle timed events
            guard let startTime = event.startTime ?? event.date else { return }
            let endTime: Date
            
            if let explicitEndTime = event.endTime {
                endTime = explicitEndTime
            } else {
                let durationSeconds = Double(event.duration ?? 3600)  // Default to 1 hour if nil
                endTime = startTime.addingTimeInterval(durationSeconds)
            }
            
            eventDescriptor.dateInterval = DateInterval(start: startTime, end: endTime)
            eventDescriptor.backgroundColor = .systemBlue
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
}
