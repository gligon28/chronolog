//
//  CalendarViewController.swift
//  chronolog
//
//  Created by Grey Ligon on 10/12/24.
//

import UIKit
import EventKit
import CalendarKit
import FirebaseFirestore
import FirebaseAuth

class CalendarViewController: DayViewController {
    
    let db = Firestore.firestore()
    let userID = Auth.auth().currentUser?.uid
    var customEvents = [CustomEvent]()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Calendar"
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
            
            db.collection("userEvents").document(userID).collection("events").getDocuments { [weak self] (querySnapshot, error) in
                if let error = error {
                    print("Error fetching documents: \(error)")
                    completion([])
                    return
                }
                
                var events = [CustomEvent]()
                for document in querySnapshot!.documents {
                    let data = document.data()
                    
                    guard let startTimestamp = data["startTime"] as? Timestamp,
                          let endTimestamp = data["endTime"] as? Timestamp,
                          let dateTimestamp = data["date"] as? Timestamp else {
                        continue
                    }
                    
                    let event = CustomEvent(
                        title: data["title"] as? String ?? "No Title",
                        date: dateTimestamp.dateValue(),
                        startTime: startTimestamp.dateValue(),
                        endTime: endTimestamp.dateValue(),
                        duration: data["duration"] as? Int ?? 0,
                        description: [data["description"] as? String ?? ""],
                        isRecurring: data["isRecurring"] as? Bool ?? false,
                        daysOfWeek: nil,
                        isAllDay: data["isAllDay"] as? Bool ?? false
                    )
                    
                    events.append(event)
                }
                
                completion(events)
            }
        }

    override func eventsForDate(_ date: Date) -> [EventDescriptor] {
        var eventDescriptors = [EventDescriptor]()
        
        let calendar = Calendar.current
        let filteredEvents = customEvents.filter { customEvent in
            return calendar.isDate(customEvent.date, inSameDayAs: date)
        }
        
        // Sort all-day events first
        let sortedEvents = filteredEvents.sorted { event1, event2 in
            if event1.isAllDay && !event2.isAllDay {
                return true
            } else if !event1.isAllDay && event2.isAllDay {
                return false
            }
            return event1.startTime ?? event1.date < event2.startTime ?? event2.date
        }
        
        for customEvent in sortedEvents {
            let eventDescriptor = Event()
            eventDescriptor.text = customEvent.title
            eventDescriptor.isAllDay = customEvent.isAllDay
            
            if customEvent.isAllDay {
                // For all-day events, set the time to span the full day
                let midnight = calendar.startOfDay(for: customEvent.date)
                let nextMidnight = calendar.date(byAdding: .day, value: 1, to: midnight)!
                eventDescriptor.dateInterval = DateInterval(start: midnight, end: nextMidnight)
            } else {
                // For regular events, use the specific times
                if let startTime = customEvent.startTime,
                   let endTime = customEvent.endTime {
                    eventDescriptor.dateInterval = DateInterval(start: startTime, end: endTime)
                } else {
                    eventDescriptor.dateInterval = DateInterval(
                        start: customEvent.date,
                        end: customEvent.date.addingTimeInterval(TimeInterval(customEvent.duration))
                    )
                }
            }
            
            // Style the event
            if customEvent.isAllDay {
                eventDescriptor.backgroundColor = .systemPurple
                eventDescriptor.textColor = .white
            } else {
                eventDescriptor.backgroundColor = .systemBlue
                eventDescriptor.textColor = .white
            }
            
            if let firstDescription = customEvent.description.first, !firstDescription.isEmpty {
                eventDescriptor.text = "\(customEvent.title)\n\(firstDescription)"
            }
            
            eventDescriptors.append(eventDescriptor)
        }
        
        return eventDescriptors
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
