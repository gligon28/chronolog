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
        guard let userID = userID else { return }
        
        db.collection("userEvents").document(userID).collection("events").getDocuments { (querySnapshot, error) in
            if let error = error {
                print("Error fetching documents: \(error)")
            } else {
                var events = [CustomEvent]()
                for document in querySnapshot!.documents {
                    let data = document.data()
                    let title = data["title"] as? String ?? "No Title"
                    let description = data["description"] as? String ?? ""
                    let isRecurring = data["isRecurring"] as? Bool ?? false
                    let daysOfWeek = data["daysOfWeek"] as? [String: Bool]

                    let startTime = (data["startTime"] as? Timestamp)?.dateValue()
                    let endTime = (data["endTime"] as? Timestamp)?.dateValue()
                    let duration = data["duration"] as? Int

                    let event = CustomEvent(
                        title: title,
                        date: (data["date"] as? Timestamp)?.dateValue(),
                        startTime: startTime,
                        endTime: endTime,
                        duration: duration,
                        description: description,
                        isRecurring: isRecurring,
                        daysOfWeek: daysOfWeek
                    )
                    events.append(event)
                }
                completion(events)
            }
        }
    }


    override func eventsForDate(_ date: Date) -> [EventDescriptor] {
        var eventDescriptors = [EventDescriptor]()
        
        let filteredEvents = customEvents.filter { event in
            if let eventDate = event.date {
                return Calendar.current.isDate(eventDate, inSameDayAs: date)
            }
            return false  // If no specific date, don't show the event
        }

        for event in filteredEvents {
            let eventDescriptor = Event()
            eventDescriptor.text = "\(event.title)\n\(event.description)"
            if let startTime = event.startTime, let endTime = event.endTime {
                eventDescriptor.dateInterval = DateInterval(start: startTime, end: endTime)
            } else if let date = event.date, let duration = event.duration {
                // Calculate the end time using the duration if specific start/end times aren't provided
                eventDescriptor.dateInterval = DateInterval(start: date, end: date.addingTimeInterval(TimeInterval(duration * 60)))
            }
            eventDescriptor.userInfo = event.description
            eventDescriptors.append(eventDescriptor)
        }
        
        return eventDescriptors
    }

    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        if viewController is CalendarViewController {
            // The calendar tab was tapped, fetch events
            (viewController as? CalendarViewController)?.fetchEvents { [weak viewController] events in
                guard let calendarVC = viewController as? CalendarViewController else { return }
                calendarVC.customEvents = events
                calendarVC.reloadData()
            }
        }
    }

    
    func parseDate(from dateString: String) -> Date? {
        let dateFormatter = ISO8601DateFormatter()
        return dateFormatter.date(from: dateString)
    }

}
