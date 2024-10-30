//
//  AddEventViewController.swift
//  chronolog
//
//  Created by Janie Giron on 10/17/24.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth
import Foundation

extension Date {
    func next(_ weekday: Int, considerToday: Bool = false) -> Date? {
        let calendar = Calendar.current
        var components = DateComponents()
        components.weekday = weekday

        // If considerToday is true and today is the target weekday, return today
        if considerToday, calendar.component(.weekday, from: self) == weekday {
            return self
        }

        // Find the next date that matches the weekday
        return calendar.nextDate(after: self, matching: components, matchingPolicy: .nextTime, direction: .forward)
    }

    func setTimeTo(time: Date) -> Date {
        let calendar = Calendar.current
        let timeComponents = calendar.dateComponents([.hour, .minute], from: time)
        guard let hour = timeComponents.hour, let minute = timeComponents.minute else { return self }
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: self) ?? self
    }
}

class AddEventViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateDateOptions()
    }
    
    var isAlertPresented: Bool = false
    
    @IBOutlet weak var recurringDateView: UIView!
    @IBOutlet weak var swtRecurringEvent: UISwitch!
    
    @IBOutlet weak var txtTitle: UITextField!
    @IBOutlet weak var txtLocation: UITextField!
    @IBOutlet weak var sgmPriority: UISegmentedControl!
    
    
    @IBOutlet weak var swtSunday: UISwitch!
    @IBOutlet weak var swtSaturday: UISwitch!
    @IBOutlet weak var stwFriday: UISwitch!
    @IBOutlet weak var swtThursday: UISwitch!
    @IBOutlet weak var swtWednesday: UISwitch!
    @IBOutlet weak var swtTuesday: UISwitch!
    @IBOutlet weak var swtMonday: UISwitch!
    
    @IBOutlet weak var endDate: UIDatePicker!
    @IBOutlet weak var startDate: UIDatePicker!
    
    @IBAction func swtRecurringEvent(_ sender: UISwitch) {
        updateDateOptions()
    }
    
    
    
    func saveEvent() {
        let title = txtTitle.text ?? ""
        let description = txtLocation.text ?? ""
        let isRecurring = swtRecurringEvent.isOn
        let originalStartTime = startDate.date
        let originalEndTime = endDate.date
        
        var daysOfWeek: [Int: Bool] = [
            1: swtSunday.isOn,
            2: swtMonday.isOn,
            3: swtTuesday.isOn,
            4: swtWednesday.isOn,
            5: swtThursday.isOn,
            6: stwFriday.isOn,
            7: swtSaturday.isOn
        ]
        
        let activeDaysOfWeek = daysOfWeek.filter { $0.value }.keys.reduce(into: [String: Bool]()) { dict, day in
            let dayName = Calendar.current.weekdaySymbols[day - 1]
            dict[dayName] = true
        }
        
        var events: [CustomEvent] = []
        
        if isRecurring {
            var currentDate = originalStartTime
            // Iterate only through each week
            while currentDate <= originalEndTime {
                for weekday in 1...7 {
                    if daysOfWeek[weekday] ?? false {
                        if let nextDate = currentDate.next(weekday, considerToday: currentDate == originalStartTime) {
                            if nextDate <= originalEndTime {
                                let adjustedStartDate = nextDate.setTimeTo(time: originalStartTime)
                                let adjustedEndDate = nextDate.setTimeTo(time: originalEndTime)
                                let event = CustomEvent(
                                    title: title,
                                    date: adjustedStartDate,  // Use startDate as the date
                                    startTime: adjustedStartDate,
                                    endTime: adjustedEndDate,
                                    duration: 0,  // Default duration
                                    description: [description],  // Wrap in array since your struct expects [String]
                                    isRecurring: isRecurring,
                                    daysOfWeek: activeDaysOfWeek,
                                    isAllDay: false  // Default to false
                                )
                                events.append(event)
                            }
                        }
                    }
                }
                // Move to the start of the next week
                currentDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: currentDate)!
            }
        } else {
            let event = CustomEvent(
                title: title,
                date: originalStartTime,  // Use startTime as the date
                startTime: originalStartTime,
                endTime: originalEndTime,
                duration: 0,  // Default duration
                description: [description],  // Wrap in array
                isRecurring: isRecurring,
                daysOfWeek: activeDaysOfWeek,
                isAllDay: false  // Default to false
            )
            events.append(event)
        }
        
        
        for event in events {
            checkForConflicts(event: event) { hasConflict in
                print(hasConflict)
                DispatchQueue.main.async {
                    if hasConflict {
                        DispatchQueue.main.async {
                            if !self.isAlertPresented {
                                let conflictAlert = UIAlertController(title: "Conflict Detected", message: "There is another event at the same time. Do you still want to add this event?", preferredStyle: .alert)
                                conflictAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                                conflictAlert.addAction(UIAlertAction(title: "Add Anyway", style: .destructive, handler: { _ in
                                    self.saveToFirebase(event: event)
                                    self.promptToAddAnotherEvent()
                                }))
                                self.present(conflictAlert, animated: true, completion: {
                                    self.isAlertPresented = true
                                })
                            }
                        }
                    } else {
                        self.saveToFirebase(event: event)
                        self.promptToAddAnotherEvent()
                    }
                }
            }
        }
    }
    
    
    func saveToFirebase(event: CustomEvent) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("Error: User is not authenticated.")
            return
        }
        
        let db = Firestore.firestore()
        
        // Prepare the event data for saving with all fields from the struct
        let eventData: [String: Any] = [
            "title": event.title,
            "date": event.date as Any,
            "startTime": event.startTime as Any,
            "endTime": event.endTime as Any,
            "duration": event.duration as Any,  // Will be saved as 0
            "description": event.description.first ?? "",  // Save first description string
            "isRecurring": event.isRecurring,
            "daysOfWeek": event.daysOfWeek as Any,
            "isAllDay": false  // Default to false
        ]
        
        // Save the document to a user-specific collection
        db.collection("userEvents").document(userID).collection("events").addDocument(data: eventData) { error in
            if let error = error {
                print("Error saving event: \(error)")
            } else {
                print("Event successfully saved")
            }
        }
    }
    
    
    func promptToAddAnotherEvent() {
        let addAnotherEventAlert = UIAlertController(title: "Event Saved", message: "Would you like to add a new event to the calendar?", preferredStyle: .alert)
        addAnotherEventAlert.addAction(UIAlertAction(title: "Add", style: .default) { (action) in
            self.addNewEvent()
        })
        addAnotherEventAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        self.present(addAnotherEventAlert, animated: true, completion: nil)
    }
    
    @IBAction func btnAddToCalendar(_ sender: UIButton) {
        saveEvent()
//        let alert = UIAlertController(title: "Event Saved", message: "Would you like to add a new event to the calendar?", preferredStyle: .alert)
//        
//        // Add actions
//        let addAction = UIAlertAction(title: "Add", style: .default) { (action) in
//            // Handle the user's decision to add an event
//            self.addNewEvent()
//        }
//        
//        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
//            // Handle the user's decision to cancel
//            self.addNewEvent()
//            alert.dismiss(animated: true, completion: nil)
//        }
//        
//        alert.addAction(addAction)
//        alert.addAction(cancelAction)
//        
//        present(alert, animated: true, completion: nil)
    }
    
    
    
    func addNewEvent() {
        txtTitle.text = ""
        txtLocation.text = ""
        
        swtRecurringEvent.isOn = false
        swtSunday.isOn = false
        swtMonday.isOn = false
        swtTuesday.isOn = false
        swtWednesday.isOn = false
        swtThursday.isOn = false
        stwFriday.isOn = false
        swtSaturday.isOn = false
        
        // Reset date pickers to current date or a specific default date
        let currentDate = Date()
        startDate.setDate(currentDate, animated: true)
        endDate.setDate(currentDate, animated: true)
        
        // Reset segmented controls if any
        sgmPriority.selectedSegmentIndex = 0  // Assuming 0 is the default segment
        
    }
    
    
    
    func updateDateOptions() {
        if swtRecurringEvent.isOn {
            recurringDateView.isHidden = false
        } else {
            recurringDateView.isHidden = true
        }
    }
    
    
    //checks for event conflict
    func eventsOnSameDay(as event: CustomEvent, allEvents: [CustomEvent]) -> [CustomEvent] {
        guard let eventDate = event.startTime else { return [] }
        let calendar = Calendar.current
        return allEvents.filter { existingEvent in
            if let existingEventDate = existingEvent.startTime {
                return calendar.isDate(eventDate, inSameDayAs: existingEventDate)
            }
            return false
        }
    }
    
    func checkForConflicts(event: CustomEvent, completion: @escaping (Bool) -> Void) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("Error: User is not authenticated.")
            completion(false) // Assume no conflict if user is not authenticated
            return
        }
        
        let db = Firestore.firestore()
        db.collection("userEvents").document(userID).collection("events").getDocuments { (snapshot, error) in
            if let error = error {
                print("Error fetching events: \(error)")
                completion(false)
            } else if let documents = snapshot?.documents {
                let hasConflict = documents.contains { document -> Bool in
                    let data = document.data()
                    let startTime = (data["startTime"] as? Timestamp)?.dateValue() ?? Date()
                    let endTime = (data["endTime"] as? Timestamp)?.dateValue() ?? Date()
                    return event.startTime! < endTime && event.endTime! > startTime
                }
                completion(hasConflict)
            }
        }
    }

    
}
