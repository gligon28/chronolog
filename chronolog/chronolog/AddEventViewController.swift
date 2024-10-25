//
//  AddEventViewController.swift
//  chronolog
//
//  Created by Janie Giron on 10/17/24.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

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
        let startTime = startDate.date
        let endTime = endDate.date
      

        var daysOfWeek: [String: Bool]? = nil
        if isRecurring {
            daysOfWeek = [
                "Sunday": swtSunday.isOn,
                "Monday": swtMonday.isOn,
                "Tuesday": swtTuesday.isOn,
                "Wednesday": swtWednesday.isOn,
                "Thursday": swtThursday.isOn,
                "Friday": stwFriday.isOn,
                "Saturday": swtSaturday.isOn
            ]
        }

        // Create a custom event instance
        let event = CustomEvent(
            title: title,
            startTime: startTime,
            endTime: endTime,
            description: description,
            isRecurring: isRecurring,
            daysOfWeek: daysOfWeek
        )
        
        // Now call a function to save this event
        print("Saving event with start time: \(String(describing: startTime)) and end time: \(String(describing: endTime))")

        saveToFirebase(event: event)
    }
    
    //function that gets daysOfTheWeek array and creates an event for every date that falls on a day that is true

    func saveToFirebase(event: CustomEvent) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("Error: User is not authenticated.")
            return
        }

        let db = Firestore.firestore()
        let eventData = [
            "title": event.title,
            "startTime": event.startTime,
            "endTime": event.endTime,
            "isRecurring": event.isRecurring,
            "daysOfWeek": event.daysOfWeek
        ] as [String : Any]

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
