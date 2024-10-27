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
            let dayName = Calendar.current.weekdaySymbols[day - 1]  // Adjust for zero-based index
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
                                    let event = CustomEvent(title: title, startTime: adjustedStartDate, endTime: adjustedEndDate, description: description, isRecurring: isRecurring, daysOfWeek: activeDaysOfWeek)
                                    events.append(event)
                                }
                            }
                        }
                    }
                    // Move to the start of the next week
                    currentDate = Calendar.current.date(byAdding: .weekOfYear, value: 1, to: currentDate)!
                }
            } else {
                let event = CustomEvent(title: title, startTime: originalStartTime, endTime: originalEndTime, description: description, isRecurring: isRecurring, daysOfWeek: nil)
                events.append(event)
            }

            for event in events {
                saveToFirebase(event: event)
            }
    }
    

    func saveToFirebase(event: CustomEvent) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("Error: User is not authenticated.")
            return
        }

        let db = Firestore.firestore()

        // Prepare the event data for saving
        let eventData = [
            "title": event.title,
            "startTime": event.startTime,
            "endTime": event.endTime,
            "isRecurring": event.isRecurring,
            "daysOfWeek": event.daysOfWeek
        ] as [String: Any]

        // Save the document to a user-specific collection
        db.collection("userEvents").document(userID).collection("events").addDocument(data: eventData) { error in
            if let error = error {
                print("Error saving event: \(error)")
            } else {
                print("Event successfully saved")
            }
        }
    }


    @IBAction func btnAddToCalendar(_ sender: UIButton) {
        saveEvent()                        
        let alert = UIAlertController(title: "Event Saved", message: "Would you like to add a new event to the calendar?", preferredStyle: .alert)
            
            // Add actions
            let addAction = UIAlertAction(title: "Add", style: .default) { (action) in
                // Handle the user's decision to add an event
                self.addNewEvent()
            }
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
                // Handle the user's decision to cancel
                self.addNewEvent()
                alert.dismiss(animated: true, completion: nil)
            }
            
            alert.addAction(addAction)
            alert.addAction(cancelAction)
            
            present(alert, animated: true, completion: nil)
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


}
