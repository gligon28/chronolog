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
                    print("Fetched event: \(title) from \(String(describing: startTime)) to \(String(describing: endTime))")

                    let event = CustomEvent(
                        title: title,
                        date: nil, // Assuming there is no direct 'date' field; adjust if needed
                        startTime: startTime,
                        endTime: endTime,
                        duration: nil, // Assuming there is no direct 'duration' field; adjust if needed
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

        let calendar = Calendar.current
        let dayIndex = calendar.component(.weekday, from: date) - 1  // Calendar's days are 1-based
        let dayName = calendar.weekdaySymbols[dayIndex]  // Correct day name based on index

        print("Date being checked: \(date)")
        print("Day name from system: \(dayName)")

        for event in customEvents {
            print("Checking event titled '\(event.title)' for date \(date): Is Recurring: \(event.isRecurring), Days of Week: \(String(describing: event.daysOfWeek))")

            if event.isRecurring {
                if let daysOfWeek = event.daysOfWeek, daysOfWeek[dayName, default: false] {
                    print("Adding recurring event: \(event.title)")
                    createEventDescriptor(for: event, appendingTo: &eventDescriptors)
                }
            } else if let startTime = event.startTime, let endTime = event.endTime, calendar.isDate(startTime, inSameDayAs: date) {
                print("Adding non-recurring event: \(event.title)")
                createEventDescriptor(for: event, appendingTo: &eventDescriptors)
            }
        }

        print("Total events for \(dayName): \(eventDescriptors.count)")
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
