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
                
                // Get all possible fields to support both event types
                let title = data["title"] as? String ?? "No Title"
                let description = data["description"] as? String ?? ""
                let isRecurring = data["isRecurring"] as? Bool ?? false
                let daysOfWeek = data["daysOfWeek"] as? [String: Bool]
                let startTime = (data["startTime"] as? Timestamp)?.dateValue()
                let endTime = (data["endTime"] as? Timestamp)?.dateValue()
                let date = (data["date"] as? Timestamp)?.dateValue() ?? startTime
                let isAllDay = data["isAllDay"] as? Bool ?? false
                let duration = data["duration"] as? Int
                
                print("Fetched event: \(title) from \(String(describing: startTime)) to \(String(describing: endTime))")

                let event = CustomEvent(
                    title: title,
                    date: date,
                    startTime: startTime,
                    endTime: endTime,
                    duration: duration,
                    description: description,
                    isRecurring: isRecurring,
                    daysOfWeek: daysOfWeek,
                    isAllDay: isAllDay
                )
                events.append(event)
            }
            completion(events)
        }
    }

    override func eventsForDate(_ date: Date) -> [EventDescriptor] {
        var eventDescriptors = [EventDescriptor]()
        let calendar = Calendar.current
        
        for event in customEvents {
            if event.isRecurring {
                // Handle recurring events
                let dayIndex = calendar.component(.weekday, from: date) - 1
                let dayName = calendar.weekdaySymbols[dayIndex]
                
                if let daysOfWeek = event.daysOfWeek, daysOfWeek[dayName, default: false] {
                    createEventDescriptor(for: event, on: date, appendingTo: &eventDescriptors)
                }
            } else {
                // Handle non-recurring events
                if let eventDate = event.startTime ?? event.date,
                   calendar.isDate(eventDate, inSameDayAs: date) {
                    createEventDescriptor(for: event, on: date, appendingTo: &eventDescriptors)
                }
            }
        }
        
        // Sort events (all-day events first)
        return eventDescriptors.sorted { event1, event2 in
            if event1.isAllDay && !event2.isAllDay { return true }
            if !event1.isAllDay && event2.isAllDay { return false }
            return event1.dateInterval.start < event2.dateInterval.start
        }
    }
    
    private func createEventDescriptor(for event: CustomEvent, on date: Date, appendingTo eventDescriptors: inout [EventDescriptor]) {
        let eventDescriptor = Event()
        eventDescriptor.text = event.description.isEmpty ? event.title : "\(event.title)\n\(event.description)"
        eventDescriptor.isAllDay = event.isAllDay
        
        let calendar = Calendar.current
        
        if event.isAllDay {
            // For all-day events
            let midnight = calendar.startOfDay(for: date)
            let nextMidnight = calendar.date(byAdding: .day, value: 1, to: midnight)!
            eventDescriptor.dateInterval = DateInterval(start: midnight, end: nextMidnight)
            eventDescriptor.backgroundColor = .systemPurple
        } else {
            // For timed events
            if let startTime = event.startTime ?? event.date,
               let endTime = event.endTime ?? calendar.date(byAdding: .minute, value: event.duration ?? 60, to: startTime) {
                eventDescriptor.dateInterval = DateInterval(start: startTime, end: endTime)
            } else {
                return
            }
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