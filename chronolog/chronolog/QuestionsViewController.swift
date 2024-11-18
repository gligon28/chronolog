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
        scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: +15).isActive = true
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
        addPrioritySegmentedControl(to: container)
        addAllDaySwitch(to: container)
        addDatePickers(to: container)
        addDurationToggle(to: container)
        addRecurrenceSelector(to: container)
        addAllowSplittingSwitch(to: container)
        addAllowOverlapSwitch(to: container)
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
    
    func addPrioritySegmentedControl(to container: UIStackView) {
        // Create a horizontal stack for label and segmented control
        let priorityContainer = UIStackView()
        priorityContainer.axis = .horizontal
        priorityContainer.spacing = 10
        
        // Priority label
        let priorityLabel = UILabel()
        priorityLabel.text = "Priority"
        priorityLabel.font = .systemFont(ofSize: 16, weight: .medium)
        priorityContainer.addArrangedSubview(priorityLabel)
        
        // Segmented control with three segments: High, Medium, Low
        let prioritySegmentedControl = UISegmentedControl(items: ["High", "Medium", "Low"])
        prioritySegmentedControl.selectedSegmentIndex = 1 // Default to Medium
        priorityContainer.addArrangedSubview(prioritySegmentedControl)
        
        // Add the priority container to the main container stack
        container.addArrangedSubview(priorityContainer)
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
    
    func addRecurrenceSelector(to container: UIStackView) {
        let recurrenceContainer = UIStackView()
        recurrenceContainer.axis = .horizontal
        recurrenceContainer.spacing = 10
        
        // Label for "Repeats"
        let recurrenceLabel = UILabel()
        recurrenceLabel.text = "Repeats"
        recurrenceLabel.font = .systemFont(ofSize: 16, weight: .medium)
        recurrenceContainer.addArrangedSubview(recurrenceLabel)
        
        // Button for selecting recurrence with arrow icon
        let recurrenceButton = UIButton(type: .system)
        recurrenceButton.setTitle("Never", for: .normal) // Default text
        recurrenceButton.tintColor = UIColor.darkGray // Set text and icon color to dark gray
        recurrenceButton.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .medium) // Match label font size
        
        // Set up button configuration with icon
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "chevron.down") // Down arrow icon
        config.imagePlacement = .trailing
        config.imagePadding = 2 // Adjust spacing between text and icon
        recurrenceButton.configuration = config
        
        recurrenceButton.addTarget(self, action: #selector(showRecurrenceOptions(_:)), for: .touchUpInside)
        recurrenceContainer.addArrangedSubview(recurrenceButton)
        container.addArrangedSubview(recurrenceContainer)
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
    
    func addAllowSplittingSwitch(to container: UIStackView) {
        // Create a horizontal stack for the label and switch
        let splittingSwitchContainer = UIStackView()
        splittingSwitchContainer.axis = .horizontal
        splittingSwitchContainer.spacing = 10
        
        // Label for "Allow Splitting"
        let splittingLabel = UILabel()
        splittingLabel.text = "Allow Splitting"
        splittingLabel.font = .systemFont(ofSize: 16, weight: .medium)
        splittingSwitchContainer.addArrangedSubview(splittingLabel)
        
        // Switch for "Allow Splitting"
        let splittingSwitch = UISwitch()
        splittingSwitch.isOn = false // Default to "No" (false)
        splittingSwitchContainer.addArrangedSubview(splittingSwitch)
        
        // Add the container with the label and switch to the main container
        container.addArrangedSubview(splittingSwitchContainer)
    }

    func addAllowOverlapSwitch(to container: UIStackView) {
        // Create a horizontal stack for the label and switch
        let overlapSwitchContainer = UIStackView()
        overlapSwitchContainer.axis = .horizontal
        overlapSwitchContainer.spacing = 10
        
        // Label for "Allow Overlap"
        let overlapLabel = UILabel()
        overlapLabel.text = "Allow Overlap"
        overlapLabel.font = .systemFont(ofSize: 16, weight: .medium)
        overlapSwitchContainer.addArrangedSubview(overlapLabel)
        
        // Switch for "Allow Overlap"
        let overlapSwitch = UISwitch()
        overlapSwitch.isOn = false // Default to "No" (false)
        overlapSwitchContainer.addArrangedSubview(overlapSwitch)
        
        // Add the container with the label and switch to the main container
        container.addArrangedSubview(overlapSwitchContainer)
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
        print("Duration picker changed: \(sender.countDownDuration / 60) minutes")
        
        guard let container = durationPickers.first(where: { $1 == sender })?.key else {
            print("Container not found for duration picker")
            return
        }

        // Retrieve specific date pickers using their associated labels
        guard let startDatePicker = findDatePicker(in: container, withLabel: "Starts"),
              let endDatePicker = findDatePicker(in: container, withLabel: "Ends") else {
            print("Start date picker or end date picker is nil")
            return
        }

        // Adjust end date based on selected duration
        let selectedDuration = sender.countDownDuration
        let newEndDate = startDatePicker.date.addingTimeInterval(selectedDuration)
        print("Setting new end date: \(newEndDate)")

        // Update the end date picker
        endDatePicker.setDate(newEndDate, animated: true)
    }



    
    func adjustEndDateIfNeeded(for container: UIStackView) {
        let startDatePicker = container.arrangedSubviews
            .compactMap { ($0 as? UIStackView)?.arrangedSubviews.first as? UIDatePicker }
            .first
        let endDatePicker = container.arrangedSubviews
            .compactMap { ($0 as? UIStackView)?.arrangedSubviews.last as? UIDatePicker }
            .first
        let durationPicker = durationPickers[container]

        // Log debug information
        if let startDatePicker = startDatePicker, let durationPicker = durationPicker {
            print("Start date: \(startDatePicker.date)")
            print("Duration selected: \(durationPicker.countDownDuration / 60) minutes")
        } else {
            print("Start date picker or duration picker is nil")
        }

        guard let startDatePicker = startDatePicker, let endDatePicker = endDatePicker, let durationPicker = durationPicker else {
            print("Missing one of the necessary pickers")
            return
        }

        let selectedDuration = durationPicker.countDownDuration
        let newEndDate = startDatePicker.date.addingTimeInterval(selectedDuration)

        print("New end date: \(newEndDate)")

        // Update the end date picker's value
        endDatePicker.setDate(newEndDate, animated: true)
    }


    
    // Update the duration switch toggle to ensure proper validation
    @objc func durationSwitchToggled(_ sender: UISwitch) {
        guard let container = sender.superview?.superview as? UIStackView,
              let picker = durationPickers[container] else { return }
        
        picker.isHidden = !sender.isOn

        if sender.isOn {
            stackView.layoutIfNeeded()

            // When turning on duration, immediately validate and adjust end date if needed
            if let startDatePicker = findDatePicker(in: container, withLabel: "Starts"),
               let endDatePicker = findDatePicker(in: container, withLabel: "Ends") {

                // Adjust end date immediately to reflect the default duration
                let requiredEndDate = startDatePicker.date.addingTimeInterval(picker.countDownDuration)
                endDatePicker.setDate(requiredEndDate, animated: true)
                endDatePicker.minimumDate = startDatePicker.date // Prevent earlier end dates

                // Debugging output
                print("Duration enabled: Adjusted end date to \(requiredEndDate)")
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

    
    @objc func showRecurrenceOptions(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Repeat", message: nil, preferredStyle: .actionSheet)
        
        let recurrenceOptions = [
            "Never", "Every Day", "Every Week", "Every 2 Weeks", "Every Month", "Every Year"
        ]
        
        for option in recurrenceOptions {
            let action = UIAlertAction(title: option, style: .default) { _ in
                sender.setTitle(option, for: .normal) // Update button title based on selection
                // Save selected recurrence option if needed
            }
            alertController.addAction(action)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        // Present the action sheet
        if let popoverController = alertController.popoverPresentationController {
            popoverController.sourceView = sender
            popoverController.sourceRect = sender.bounds
        }
        present(alertController, animated: true, completion: nil)
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
                    
                    // Add tolerance to the duration validation
                    let tolerance: TimeInterval = 1.0 // Allow 1-second lenience
                    if timeDifference + tolerance < duration {
                        showAlert(title: "Invalid Duration", message: "The time difference between the start and end dates cannot be less than the specified duration.")
                        return false
                    }
                    
                    // Debugging output for validation
                    print("Duration set: \(duration) seconds")
                    print("Time difference: \(timeDifference) seconds")
                    print("Tolerance applied: \(tolerance) seconds")
                }
            }
        }
        return true
    }
    
    // Helper method to find a date picker in a container with a specific label
    func findDatePicker(in container: UIStackView, withLabel labelText: String) -> UIDatePicker? {
        for subview in container.arrangedSubviews {
            if let stackView = subview as? UIStackView {
                let label = stackView.arrangedSubviews.first(where: { ($0 as? UILabel)?.text == labelText })
                let picker = stackView.arrangedSubviews.first(where: { $0 is UIDatePicker }) as? UIDatePicker
                if label != nil, picker != nil {
                    return picker
                }
            }
        }
        return nil
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
            
            // Gather all the relevant fields from UI components
            let titleField = container.arrangedSubviews.first(where: { $0 is UITextField }) as? UITextField
            let startDatePicker = container.arrangedSubviews.compactMap { ($0 as? UIStackView)?.arrangedSubviews.last as? UIDatePicker }.first
            let endDatePicker = container.arrangedSubviews.compactMap { ($0 as? UIStackView)?.arrangedSubviews.last as? UIDatePicker }.last
            let allDaySwitch = container.arrangedSubviews
                .compactMap { $0 as? UIStackView }
                .first { stack in stack.arrangedSubviews.contains { ($0 as? UILabel)?.text == "All-day" } }?
                .arrangedSubviews.compactMap { $0 as? UISwitch }.first
            let noteTextField = container.arrangedSubviews
                .compactMap { $0 as? UIStackView }
                .first { stack in stack.arrangedSubviews.contains { ($0 as? UILabel)?.text == "Add a Note" } }?
                .arrangedSubviews.compactMap { $0 as? UITextField }.first
            let durationPicker = durationPickers[container]
            let allowSplitSwitch = container.arrangedSubviews
                .compactMap { $0 as? UIStackView }
                .first { stack in stack.arrangedSubviews.contains { ($0 as? UILabel)?.text == "Allow Splitting" } }?
                .arrangedSubviews.compactMap { $0 as? UISwitch }.first
            let allowOverlapSwitch = container.arrangedSubviews
                .compactMap { $0 as? UIStackView }
                .first { stack in stack.arrangedSubviews.contains { ($0 as? UILabel)?.text == "Allow Overlap" } }?
                .arrangedSubviews.compactMap { $0 as? UISwitch }.first
            let priorityControl = container.arrangedSubviews
                .compactMap { $0 as? UIStackView }
                .first { stack in stack.arrangedSubviews.contains { ($0 as? UILabel)?.text == "Priority" } }?
                .arrangedSubviews.compactMap { $0 as? UISegmentedControl }.first

            if let title = titleField?.text,
               let startDate = startDatePicker?.date,
               let endDate = endDatePicker?.date {
                
                let isAllDay = allDaySwitch?.isOn ?? false
                let allowSplit = allowSplitSwitch?.isOn ?? false
                let allowOverlap = allowOverlapSwitch?.isOn ?? false
                let priority: CustomEvent.Priority = {
                    switch priorityControl?.selectedSegmentIndex {
                    case 0: return .high
                    case 1: return .medium
                    case 2: return .low
                    default: return .medium
                    }
                }()
                let duration = Int(durationPicker?.countDownDuration ?? 0)
                let description = noteTextField?.text ?? ""

                // Create CustomEvent instance
                let customEvent = CustomEvent(
                    title: title,
                    date: startDate,
                    startTime: startDate,
                    endTime: endDate,
                    duration: duration,
                    description: [description],
                    isRecurring: false,
                    daysOfWeek: nil,
                    isAllDay: isAllDay,
                    allowSplit: allowSplit,
                    allowOverlap: allowOverlap,
                    priority: priority
                )

                // Prepare data for Firebase using the CustomEvent instance
                let eventData: [String: Any] = [
                    "title": customEvent.title,
                    "date": Timestamp(date: customEvent.date ?? Date()),
                    "startTime": Timestamp(date: customEvent.startTime ?? Date()),
                    "endTime": Timestamp(date: customEvent.endTime ?? Date()),
                    "duration": customEvent.duration,
                    "description": customEvent.description.joined(separator: "\n"),
                    "isRecurring": customEvent.isRecurring,
                    "isAllDay": customEvent.isAllDay,
                    "allowSplit": customEvent.allowSplit,
                    "allowOverlap": customEvent.allowOverlap,
                    "priority": customEvent.priority.rawValue
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
            isAllDay: isAllDay,
            allowSplit: false,
            allowOverlap: false,
            priority: .medium
        )
    }
    
    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }


}
