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

                    let event = CustomEvent(
                        title: title,
                        startTime: startTime,
                        endTime: endTime,
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

        for event in customEvents {
            // Get the day key directly using a more reliable method
            let dayKey = Calendar.current.weekdaySymbols[Calendar.current.component(.weekday, from: date) - 1]

            // Check if it's a recurring event and recurs on this day
            if event.isRecurring, let daysOfWeek = event.daysOfWeek, daysOfWeek[dayKey, default: false] {
                createEventDescriptor(for: event, appendingTo: &eventDescriptors)
            } else if !event.isRecurring, let startTime = event.startTime, let endTime = event.endTime, Calendar.current.isDate(startTime, inSameDayAs: date) {
                // Handle non-recurring event that matches the date
                createEventDescriptor(for: event, appendingTo: &eventDescriptors)
            }
        }

        return eventDescriptors
    }

    
    private func createEventDescriptor(for event: CustomEvent, appendingTo eventDescriptors: inout [EventDescriptor]) {
        let eventDescriptor = Event()
        eventDescriptor.text = "\(event.title)\n\(event.description)"
        if let startTime = event.startTime, let endTime = event.endTime, startTime <= endTime {
            eventDescriptor.dateInterval = DateInterval(start: startTime, end: endTime)
        } else {
            print("Invalid time interval for event: \(event.title)")
            return
        }
        eventDescriptor.userInfo = event.description
        eventDescriptors.append(eventDescriptor)
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
