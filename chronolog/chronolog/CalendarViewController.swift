//
//  CalendarViewController.swift
//  chronolog
//
//  Created by Janie Giron on 10/12/24.
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
        guard let userID = userID else { return }
        
        db.collection("userEvents").document(userID).collection("events").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error fetching documents: \(error)")
            } else {
                print("Query snapshot: \(querySnapshot?.documents ?? [])")

                var events = [CustomEvent]()
                for document in querySnapshot!.documents {
                    print("Document data: \(document.data())")
                    let data = document.data()
                    let title = data["title"] as? String ?? "No Title"
                    // Change from String to Timestamp for date field
                    if let timestamp = data["date"] as? Timestamp {
                        let date = timestamp.dateValue() // Convert Firestore Timestamp to Date
                                        
                        let duration = data["duration"] as? Int ?? 0
                        let description = data["description"] as? String ?? ""
                        let event = CustomEvent(title: title, date: date, duration: duration, description: description)
                                        events.append(event)
                    } else {
                        print("Error: Missing or invalid date field.")
                    }
                }
                print("Fetched events: \(events)")
                completion(events)
            }
        }
    }

    // Override this method to provide events for a given date
    override func eventsForDate(_ date: Date) -> [EventDescriptor] {
        var eventDescriptors = [EventDescriptor]()
            
        // Filter custom events to get those for the given date
        let calendar = Calendar.current
        let filteredEvents = customEvents.filter { customEvent in
            return calendar.isDate(customEvent.date, inSameDayAs: date)
        }
            
        // Convert filtered custom events to CalendarKit EventDescriptor
        for customEvent in filteredEvents {
            let eventDescriptor = Event() // CalendarKit EventDescriptor
                
            eventDescriptor.text = customEvent.title
            eventDescriptor.dateInterval = DateInterval(start: customEvent.date,
                                                            end: customEvent.date.addingTimeInterval(TimeInterval(customEvent.duration * 60)))
            eventDescriptor.userInfo = customEvent.description
                
            eventDescriptors.append(eventDescriptor)
        }
            
        return eventDescriptors
    }
    
    func parseDate(from dateString: String) -> Date? {
        let dateFormatter = ISO8601DateFormatter()
        return dateFormatter.date(from: dateString)
    }

}
