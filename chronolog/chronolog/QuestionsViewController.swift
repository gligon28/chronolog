import UIKit
import FirebaseFirestore
import Firebase
import FirebaseAuth

class QuestionsViewController: UIViewController {

    var selectedActivities: [Activity] = []
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackView: UIStackView!
    let saveButton = UIButton(type: .system)
    var durationPickers: [UIStackView: UIDatePicker] = [:]

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(scrollView)
        view.addSubview(saveButton)

        setupScrollView()
        setupActivitySections()
        setupSaveButton()
    }

    @IBAction func btnSignOut(_ sender: UIButton) {
        do {
            try Auth.auth().signOut()
            activeUser = nil
            // Navigate back to login screen
            self.performSegue(withIdentifier: "goToLogin2", sender: self)
        } catch let error {
            print("Error signing out: \(error.localizedDescription)")
            // Show error alert
            let alert = UIAlertController(
                title: "Error",
                message: "Failed to sign out: \(error.localizedDescription)",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(alert, animated: true)
        }
    }
    
    func setupScrollView() {
        // Configure scroll view
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: saveButton.topAnchor, constant: -10).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true

        // Add stack view to scroll view
        scrollView.addSubview(stackView)
        stackView.axis = .vertical
        stackView.spacing = 15
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 10).isActive = true
        stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -10).isActive = true
        stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16).isActive = true
        stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16).isActive = true
        stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32).isActive = true
    }

    func setupActivitySections() {
        for (index, activity) in selectedActivities.enumerated() {
            // Header button for expanding/collapsing with UIButton.Configuration
            let headerButton = createHeaderButton(for: activity, index: index)
            
            // Pass `index == 0` to make only the first activity initially open
            let container = createActivityDetailContainer(isInitiallyOpen: index == 0, for: activity)
            
            // Add header and container to the stack view
            stackView.addArrangedSubview(headerButton)
            stackView.addArrangedSubview(container)
        }
    }

    func createHeaderButton(for activity: Activity, index: Int) -> UIButton {
        let headerButton = UIButton(type: .system)
        var config = UIButton.Configuration.plain()
        config.title = activity.name
        config.baseForegroundColor = .systemOrange
        config.titleAlignment = .leading
        config.image = UIImage(systemName: index == 0 ? "chevron.up" : "chevron.down")
        config.imagePlacement = .trailing
        config.imagePadding = 10
        config.attributedTitle = AttributedString(activity.name, attributes: AttributeContainer([.font: UIFont.boldSystemFont(ofSize: 18)]))
        headerButton.configuration = config
        headerButton.tag = index // Use tag to track index for toggling
        headerButton.addTarget(self, action: #selector(toggleSection(_:)), for: .touchUpInside)
        return headerButton
    }

    func createActivityDetailContainer(isInitiallyOpen: Bool, for activity: Activity) -> UIStackView {
        // Create container stack for each activity's details
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 15
        container.backgroundColor = UIColor(white: 0.95, alpha: 1)
        container.layer.cornerRadius = 10
        container.layoutMargins = UIEdgeInsets(top: 10, left: 15, bottom: 15, right: 15)
        container.isLayoutMarginsRelativeArrangement = true
        container.isHidden = !isInitiallyOpen // Set initial visibility based on flag

        // Editable name text field
        let nameTextField = UITextField()
        nameTextField.text = activity.name // Default to the activity name
        nameTextField.borderStyle = .roundedRect
        nameTextField.font = .systemFont(ofSize: 18, weight: .medium)
        nameTextField.clearButtonMode = .whileEditing
        nameTextField.tag = stackView.arrangedSubviews.count // Use tag to track for saving
        container.addArrangedSubview(nameTextField)
        
        addLocationField(to: container)
        addAllDaySwitch(to: container)
        addDatePickers(to: container)
        addDurationToggle(to: container)
        addNoteTextField(placeholder: "", to: container)
        
        // Configure elements based on activity type
//        switch activity.name {
////        case "Work":
////            addLocationField(to: container)
////            addAllDaySwitch(to: container)
////            addDatePickers(to: container)
////            addNoteTextField(placeholder: "", to: container)
////        case "Exercise":
////            addAllDaySwitch(to: container)
////            addDatePickers(to: container)
////            addNoteTextField(placeholder: "", to: container)
////        case "Hobbies":
////            addDatePickers(to: container)
////            addNoteTextField(placeholder: "", to: container)
//        default:
//            addLocationField(to: container)
//            addAllDaySwitch(to: container)
//            addDatePickers(to: container)
//            addDurationToggle(to: container)
//            addNoteTextField(placeholder: "", to: container)
//        }

        return container
    }
    
    // Helper methods to add common UI elements
    func addAllDaySwitch(to container: UIStackView) {
        let allDaySwitchContainer = UIStackView()
        allDaySwitchContainer.axis = .horizontal
        allDaySwitchContainer.spacing = 10
        let allDayLabel = UILabel()
        allDayLabel.text = "All-day"
        allDayLabel.font = .systemFont(ofSize: 16, weight: .medium)
        let allDaySwitch = UISwitch()
        allDaySwitch.addTarget(self, action: #selector(allDaySwitchToggled(_:)), for: .valueChanged)

        allDaySwitchContainer.addArrangedSubview(allDayLabel)
        allDaySwitchContainer.addArrangedSubview(allDaySwitch)
        container.addArrangedSubview(allDaySwitchContainer)
    }

    func addDatePickers(to container: UIStackView) {
        let now = Date() // current date/time
        
        // Horizontal stack for start label and date picker
        let startContainer = UIStackView()
        startContainer.axis = .horizontal
        startContainer.spacing = 10

        // Start label
        let startLabel = UILabel()
        startLabel.text = "Starts"
        startLabel.font = .systemFont(ofSize: 16, weight: .medium)
        startContainer.addArrangedSubview(startLabel)
        
        // Start date picker
        let startDatePicker = UIDatePicker()
        startDatePicker.datePickerMode = .dateAndTime
        startDatePicker.timeZone = TimeZone.current
        startDatePicker.locale = Locale.current      // Set to user's current locale
//        startDatePicker.preferredDatePickerStyle = .inline
        startDatePicker.minimumDate = now
        startDatePicker.addTarget(self, action: #selector(startDateChanged(_:)), for: .valueChanged)
        startContainer.addArrangedSubview(startDatePicker)
        
        container.addArrangedSubview(startContainer) // Add startContainer to main container

        // Horizontal stack for end label and date picker
        let endContainer = UIStackView()
        endContainer.axis = .horizontal
        endContainer.spacing = 10

        // End label
        let endLabel = UILabel()
        endLabel.text = "Ends"
        endLabel.font = .systemFont(ofSize: 16, weight: .medium)
        endContainer.addArrangedSubview(endLabel)
        
        // End date picker
        let endDatePicker = UIDatePicker()
        endDatePicker.datePickerMode = .dateAndTime
        endDatePicker.timeZone = TimeZone.current // Set to user's current time zone
        endDatePicker.locale = Locale.current      // Set to user's current locale
//        endDatePicker.preferredDatePickerStyle = .inline
        endDatePicker.minimumDate = now // Prevent selecting dates in the past
        endDatePicker.addTarget(self, action: #selector(endDateChanged(_:)), for: .valueChanged)
        endContainer.addArrangedSubview(endDatePicker)

        container.addArrangedSubview(endContainer) // Add endContainer to main container
    }
    
    func addDurationToggle(to container: UIStackView) {
        // Create a horizontal stack for the label and switch
        let durationToggleContainer = UIStackView()
        durationToggleContainer.axis = .horizontal
        durationToggleContainer.spacing = 10
        
        // Duration Label
        let durationLabel = UILabel()
        durationLabel.text = "Add Duration"
        durationLabel.font = .systemFont(ofSize: 16, weight: .medium)
        durationToggleContainer.addArrangedSubview(durationLabel)
        
        // Duration Switch
        let durationSwitch = UISwitch()
        durationSwitch.isOn = false // Default is off
        durationSwitch.addTarget(self, action: #selector(durationSwitchToggled(_:)), for: .valueChanged)
        durationToggleContainer.addArrangedSubview(durationSwitch)
        
        container.addArrangedSubview(durationToggleContainer)
        
        // Duration Picker (hidden by default)
        let picker = UIDatePicker()
        picker.datePickerMode = .countDownTimer
        picker.countDownDuration = 3600 // Default to 1 hour (3600 seconds)
        picker.isHidden = true
        picker.addTarget(self, action: #selector(durationPickerChanged(_:)), for: .valueChanged)
        container.addArrangedSubview(picker)
        
        // Store reference to the picker in the dictionary
        durationPickers[container] = picker
    }
    
    func addNoteTextField(placeholder: String, to container: UIStackView) {
        let noteContainer = UIStackView()
        noteContainer.axis = .vertical
        noteContainer.spacing = 8
        
        let noteLabel = UILabel()
        noteLabel.text = "Add a Note"
        noteLabel.font = .systemFont(ofSize: 16, weight: .medium)
        
        let noteTextField = UITextField()
        noteTextField.placeholder = placeholder
        noteTextField.borderStyle = .roundedRect
        
        noteContainer.addArrangedSubview(noteLabel)
        noteContainer.addArrangedSubview(noteTextField)
        
        container.addArrangedSubview(noteContainer)
    }
    
    func addLocationField(to container: UIStackView) {
        let locationLabel = UILabel()
        locationLabel.text = "Location"
        locationLabel.font = .systemFont(ofSize: 16, weight: .medium)
        
        let locationTextField = UITextField()
        locationTextField.placeholder = "Enter location"
        locationTextField.borderStyle = .roundedRect
        
//        container.addArrangedSubview(locationLabel)
        container.addArrangedSubview(locationTextField)
    }
    
    func setupSaveButton() {
        // Configure save button
        view.addSubview(saveButton)
        saveButton.translatesAutoresizingMaskIntoConstraints = false
        saveButton.setTitle("Save & Finish", for: .normal)
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.backgroundColor = .systemOrange
        saveButton.layer.cornerRadius = 8
        saveButton.addTarget(self, action: #selector(saveAndFinish), for: .touchUpInside)
        
        // Position save button at the bottom of the view
        saveButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16).isActive = true
        saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16).isActive = true
        saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: 0).isActive = true
        saveButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
    }
    
    //MARK: -Actions and Event Handlers
    
    // Add method to handle all-day switch toggle
    @objc func allDaySwitchToggled(_ sender: UISwitch) {
        guard let container = sender.superview?.superview as? UIStackView else { return }
        
        // Find the date pickers
        let datePickers = container.arrangedSubviews
            .compactMap { $0 as? UIStackView }
            .flatMap { $0.arrangedSubviews }
            .compactMap { $0 as? UIDatePicker }
        
        // Update date picker mode based on all-day status
        for picker in datePickers {
            picker.datePickerMode = sender.isOn ? .date : .dateAndTime
        }
    }
    
    @objc func startDateChanged(_ sender: UIDatePicker) {
        guard let container = sender.superview?.superview as? UIStackView else { return }
        let endDatePicker = container.arrangedSubviews
            .compactMap { ($0 as? UIStackView)?.arrangedSubviews.last as? UIDatePicker }.last
        let durationPicker = durationPickers[container]

        // Update end date if it’s earlier than the new start date or violates duration
        if let endDatePicker = endDatePicker {
            // If duration is set, enforce it
            if let durationPicker = durationPicker, durationPicker.isHidden == false {
                let requiredEndDate = sender.date.addingTimeInterval(durationPicker.countDownDuration)
                if endDatePicker.date < requiredEndDate {
                    endDatePicker.date = requiredEndDate
                }
                endDatePicker.minimumDate = requiredEndDate
            } else {
                // Without duration, just ensure endDate is after startDate
                if sender.date > endDatePicker.date {
                    endDatePicker.date = sender.date
                }
                endDatePicker.minimumDate = sender.date
            }
        }
        // Format date for logging with proper time zone
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone.current
        print("Updated Start Date (Local Time):", formatter.string(from: sender.date))
    }

    @objc func endDateChanged(_ sender: UIDatePicker) {
        guard let container = sender.superview?.superview as? UIStackView else { return }
        let startDatePicker = container.arrangedSubviews
            .compactMap { ($0 as? UIStackView)?.arrangedSubviews.first as? UIDatePicker }.first
        let durationPicker = durationPickers[container]

        if let startDatePicker = startDatePicker, let durationPicker = durationPicker, durationPicker.isHidden == false {
            let requiredEndDate = startDatePicker.date.addingTimeInterval(durationPicker.countDownDuration)
            if sender.date < requiredEndDate {
                sender.date = requiredEndDate
            }
        }
        // Format date for logging with proper time zone
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        formatter.timeZone = TimeZone.current
        print("Updated End Date (Local Time):", formatter.string(from: sender.date))
    }

    @objc func durationPickerChanged(_ sender: UIDatePicker) {
        // Adjust the end date when the duration changes
        guard let container = sender.superview as? UIStackView else { return }
        adjustEndDateIfNeeded(for: container)
    }

    func adjustEndDateIfNeeded(for container: UIStackView) {
        // Retrieve start and end date pickers
        let startDatePicker = container.arrangedSubviews
            .compactMap { ($0 as? UIStackView)?.arrangedSubviews.last as? UIDatePicker }.first
        let endDatePicker = container.arrangedSubviews
            .compactMap { ($0 as? UIStackView)?.arrangedSubviews.last as? UIDatePicker }.last
        let durationPicker = durationPickers[container]

        guard let startDatePicker = startDatePicker, let endDatePicker = endDatePicker, let durationPicker = durationPicker else { return }

        // Calculate the target end date based on start date and duration
        let requiredEndDate = startDatePicker.date.addingTimeInterval(durationPicker.countDownDuration)
        
        // Adjust the end date if it is earlier than the required end date
        if endDatePicker.date < requiredEndDate {
            endDatePicker.setDate(requiredEndDate, animated: true)
        }
    }
    
    // Update the duration switch toggle to ensure proper validation
    @objc func durationSwitchToggled(_ sender: UISwitch) {
        guard let container = sender.superview?.superview as? UIStackView,
              let picker = durationPickers[container] else { return }
        
        picker.isHidden = !sender.isOn
        
        if sender.isOn {
            stackView.layoutIfNeeded()
            
            // When turning on duration, immediately validate and adjust end date if needed
            if let startDate = findDatePicker(in: container, withLabel: "Starts")?.date,
               let endDatePicker = findDatePicker(in: container, withLabel: "Ends") {
                
                let requiredEndDate = startDate.addingTimeInterval(picker.countDownDuration)
                if endDatePicker.date < requiredEndDate {
                    endDatePicker.setDate(requiredEndDate, animated: true)
                }
                endDatePicker.minimumDate = requiredEndDate
            }
            
            // Scroll to show the duration picker if needed
            let containerBottomY = container.frame.maxY + 20
            let visibleBottom = scrollView.contentOffset.y + scrollView.bounds.height
            
            if containerBottomY > visibleBottom {
                let offsetY = containerBottomY - scrollView.bounds.height + 20
                scrollView.setContentOffset(CGPoint(x: 0, y: offsetY), animated: true)
            }
        }
    }

    @objc func toggleSection(_ sender: UIButton) {
        guard let index = stackView.arrangedSubviews.firstIndex(of: sender),
              let container = stackView.arrangedSubviews[index + 1] as? UIStackView else { return }
        
        container.isHidden.toggle()
        
        // Update arrow image based on expanded/collapsed state
        var config = sender.configuration
        config?.image = container.isHidden ? UIImage(systemName: "chevron.down") : UIImage(systemName: "chevron.up")
        sender.configuration = config
        
        // Only scroll if the container is being expanded
        if !container.isHidden {
            // Layout the stack view to ensure frames are updated after changing visibility
            stackView.layoutIfNeeded()
            
            // Calculate the bottom position of the expanded container within the scroll view
            let containerBottomY = container.frame.maxY + 10 // Small padding for better visibility
            
            // Calculate the currently visible area within the scroll view
            let visibleBottom = scrollView.contentOffset.y + scrollView.bounds.height
            
            // Calculate the position of the next activity header (if it exists)
            let nextActivityIndex = index + 2
            var targetY = containerBottomY
            
            if nextActivityIndex < stackView.arrangedSubviews.count {
                // If there’s a next activity, scroll just enough to bring the next one into view
                let nextActivity = stackView.arrangedSubviews[nextActivityIndex]
                targetY = min(containerBottomY, nextActivity.frame.minY)
            }
            
            // Only scroll if the target position is beyond the currently visible area
            if targetY > visibleBottom {
                let offsetY = targetY - scrollView.bounds.height + 10 // Add a small padding
                scrollView.setContentOffset(CGPoint(x: 0, y: offsetY), animated: true)
            }
        }
    }

    @objc func saveAndFinish() {
        if validateEventData() {
            saveEventsToFirebase()
            performSegue(withIdentifier: "goToNext", sender: self)
        }
    }

    func validateEventData() -> Bool {
        for (index, view) in stackView.arrangedSubviews.enumerated() where index % 2 == 1 {
            guard let container = view as? UIStackView else { continue }

            // Find title field
            let titleField = container.arrangedSubviews.first(where: { $0 is UITextField }) as? UITextField
            
            // Find date pickers within their container stacks
            let startDatePicker = container.arrangedSubviews
                .compactMap { $0 as? UIStackView }
                .first { stack in
                    stack.arrangedSubviews.contains { view in
                        (view as? UILabel)?.text == "Starts"
                    }
                }?.arrangedSubviews
                .compactMap { $0 as? UIDatePicker }
                .first
            
            let endDatePicker = container.arrangedSubviews
                .compactMap { $0 as? UIStackView }
                .first { stack in
                    stack.arrangedSubviews.contains { view in
                        (view as? UILabel)?.text == "Ends"
                    }
                }?.arrangedSubviews
                .compactMap { $0 as? UIDatePicker }
                .first
                
            // Get duration picker
            let durationPicker = durationPickers[container]
            
            // Validate dates and duration
            if let startDate = startDatePicker?.date,
               let endDate = endDatePicker?.date {
                
                // First check if end date is before start date
                if endDate < startDate {
                    showAlert(title: "Invalid Date Range", message: "End date cannot be before the start date.")
                    return false
                }
                
                // Then check duration if the duration picker is visible
                if let durationPicker = durationPicker,
                   !durationPicker.isHidden {
                    let duration = durationPicker.countDownDuration
                    let timeDifference = endDate.timeIntervalSince(startDate)
                    
                    // Add some logging to debug
                    print("Duration set: \(duration) seconds")
                    print("Time difference: \(timeDifference) seconds")
                    
                    if timeDifference < duration {
                        showAlert(title: "Invalid Duration", message: "The time difference between the start and end dates cannot be less than the specified duration.")
                        return false
                    }
                }
            }
        }
        return true
    }
    
    // Helper method to find a date picker in a container with a specific label
    private func findDatePicker(in container: UIStackView, withLabel labelText: String) -> UIDatePicker? {
        return container.arrangedSubviews
            .compactMap { $0 as? UIStackView }
            .first { stack in
                stack.arrangedSubviews.contains { view in
                    (view as? UILabel)?.text == labelText
                }
            }?.arrangedSubviews
            .compactMap { $0 as? UIDatePicker }
            .first
    }
    
    
    func saveEventsToFirebase() {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        let db = Firestore.firestore()
        
        // Create a date formatter for consistent timezone handling
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.current
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss Z"
        
        for (index, view) in stackView.arrangedSubviews.enumerated() where index % 2 == 1 {
            guard let container = view as? UIStackView else { continue }
            
            // Find all the relevant fields
            let titleField = container.arrangedSubviews.first(where: { $0 is UITextField }) as? UITextField
            let startDatePicker = container.arrangedSubviews.compactMap { ($0 as? UIStackView)?.arrangedSubviews.last as? UIDatePicker }.first
            let endDatePicker = container.arrangedSubviews.compactMap { ($0 as? UIStackView)?.arrangedSubviews.last as? UIDatePicker }.last
            
            // Find the all-day switch
            let allDaySwitch = container.arrangedSubviews
                .compactMap { $0 as? UIStackView }
                .first { stack in
                    stack.arrangedSubviews.contains { view in
                        (view as? UILabel)?.text == "All-day"
                    }
                }?.arrangedSubviews
                .compactMap { $0 as? UISwitch }
                .first
            
            // Find the note text field
            let noteTextField = container.arrangedSubviews
                .compactMap { $0 as? UIStackView }
                .first { stack in
                    stack.arrangedSubviews.contains { view in
                        (view as? UILabel)?.text == "Add a Note"
                    }
                }?.arrangedSubviews
                .compactMap { $0 as? UITextField }
                .first
            
            let durationPicker = durationPickers[container]
            
            if let title = titleField?.text,
               let startDate = startDatePicker?.date,
               let endDate = endDatePicker?.date {
                
                let isAllDay = allDaySwitch?.isOn ?? false
                
                // Convert dates to the user's timezone
                let calendar = Calendar.current
                let timeZone = TimeZone.current
                
                // If it's an all-day event, adjust the dates to span the full day
                let adjustedStartDate: Date
                let adjustedEndDate: Date
                
                if isAllDay {
                    // For all-day events, set start to midnight and end to 23:59:59
                    var startComponents = calendar.dateComponents([.year, .month, .day], from: startDate)
                    startComponents.hour = 0
                    startComponents.minute = 0
                    startComponents.second = 0
                    
                    var endComponents = calendar.dateComponents([.year, .month, .day], from: endDate)
                    endComponents.hour = 23
                    endComponents.minute = 59
                    endComponents.second = 59
                    
                    adjustedStartDate = calendar.date(from: startComponents) ?? startDate
                    adjustedEndDate = calendar.date(from: endComponents) ?? endDate
                } else {
                    // For regular events, just adjust for timezone
                    let startComponents = calendar.dateComponents(in: timeZone, from: startDate)
                    let endComponents = calendar.dateComponents(in: timeZone, from: endDate)
                    
                    adjustedStartDate = calendar.date(from: startComponents) ?? startDate
                    adjustedEndDate = calendar.date(from: endComponents) ?? endDate
                }
                
                let duration = durationPicker?.countDownDuration ?? 0
                let description = noteTextField?.text ?? ""
                
                // Log the dates for verification
                print("Original Start Date:", dateFormatter.string(from: startDate))
                print("Adjusted Start Date:", dateFormatter.string(from: adjustedStartDate))
                print("Original End Date:", dateFormatter.string(from: endDate))
                print("Adjusted End Date:", dateFormatter.string(from: adjustedEndDate))
                print("Is All Day:", isAllDay)
                
                // Prepare data for Firebase using Timestamps
                let eventData: [String: Any] = [
                    "title": title,
                    "date": Timestamp(date: adjustedStartDate),
                    "startTime": Timestamp(date: adjustedStartDate),
                    "endTime": Timestamp(date: adjustedEndDate),
                    "duration": Int(duration),
                    "description": description,
                    "isRecurring": false,
                    "isAllDay": isAllDay,
                    "daysOfWeek": NSNull()
                ]
                
                // Save to Firebase
                db.collection("userEvents").document(userID).collection("events").addDocument(data: eventData) { error in
                    if let error = error {
                        print("Error saving event to Firebase: \(error)")
                    } else {
                        print("Event saved successfully")
                        print("Saved event data:", eventData)
                    }
                }
            }
        }
    }


    func createCustomEvent(title: String, date: Date, startTime: Date, endTime: Date, duration: Int, description: String, isRecurring: Bool = false, isAllDay: Bool = false) -> CustomEvent {
        return CustomEvent(
            title: title,
            date: date,
            startTime: startTime,
            endTime: endTime,
            duration: duration,
            description: [description],
            isRecurring: isRecurring,
            daysOfWeek: nil,
            isAllDay: isAllDay
        )
    }
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }




}
