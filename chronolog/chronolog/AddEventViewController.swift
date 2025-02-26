import UIKit
import FirebaseFirestore
import FirebaseAuth
import Firebase

class AddEventViewController: UIViewController {
    // Scroll View and Stack View
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var stackView: UIStackView!
    
    // Duration Pickers Dictionary
    var durationPickers: [UIStackView: UIDatePicker] = [:]

    // Save Button
    let saveButton = UIButton(type: .system)
    let resetButton = UIButton(type: .system)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(scrollView)
        view.addSubview(saveButton)
        view.addSubview(resetButton)
        
        setupScrollView()
        setupActivityDetailContainer()
        setupActionButtons()
    }

    // MARK: - Scroll View Setup
    func setupScrollView() {
        // Add scroll view to the main view
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        // Constraints for the scroll view
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 15),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: saveButton.topAnchor, constant: -10) // Reference saveButton
        ])

        // Add stack view to the scroll view
        scrollView.addSubview(stackView)
        stackView.axis = .vertical
        stackView.spacing = 15
        stackView.translatesAutoresizingMaskIntoConstraints = false

        // Constraints for the stack view
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor, constant: 10),
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor, constant: 16),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor, constant: -16),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: -10),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor, constant: -32)
        ])
        
        print(scrollView.superview as Any)
    }

    // MARK: - Setup Save and Reset Buttons
        func setupActionButtons() {
            view.addSubview(saveButton)
            view.addSubview(resetButton)

            saveButton.translatesAutoresizingMaskIntoConstraints = false
            resetButton.translatesAutoresizingMaskIntoConstraints = false

            // Configure Save Button
            saveButton.setTitle("Save Event", for: .normal)
            saveButton.setTitleColor(.white, for: .normal)
            saveButton.backgroundColor = .systemOrange
            saveButton.layer.cornerRadius = 8
            saveButton.addTarget(self, action: #selector(saveEvent), for: .touchUpInside)

            // Configure Reset Button
            resetButton.setTitle("Reset", for: .normal)
            resetButton.setTitleColor(.white, for: .normal)
            resetButton.backgroundColor = .systemGray
            resetButton.layer.cornerRadius = 8
            resetButton.addTarget(self, action: #selector(resetForm), for: .touchUpInside)

            // Set up constraints for the buttons
            NSLayoutConstraint.activate([
                // Reset Button Constraints
                resetButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
                resetButton.trailingAnchor.constraint(equalTo: saveButton.leadingAnchor, constant: -10),
                resetButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
                resetButton.heightAnchor.constraint(equalToConstant: 50),
                resetButton.widthAnchor.constraint(equalTo: saveButton.widthAnchor),

                // Save Button Constraints
                saveButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
                saveButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
                saveButton.heightAnchor.constraint(equalToConstant: 50),
            ])
        }



    // MARK: - Activity Detail Container Setup
    func setupActivityDetailContainer() {
        let container = UIStackView()
        container.axis = .vertical
        container.spacing = 15
        container.backgroundColor = UIColor(white: 0.95, alpha: 1)
        container.layer.cornerRadius = 10
        container.layoutMargins = UIEdgeInsets(top: 10, left: 15, bottom: 15, right: 15)
        container.isLayoutMarginsRelativeArrangement = true
        stackView.addArrangedSubview(container)

        
        // Editable name text field
        let nameTextField = UITextField()
        nameTextField.placeholder = "Enter title"
        nameTextField.borderStyle = .roundedRect
        nameTextField.font = .systemFont(ofSize: 18, weight: .medium)
        nameTextField.clearButtonMode = .whileEditing
        nameTextField.tag = stackView.arrangedSubviews.count // Use tag to track for saving
        container.addArrangedSubview(nameTextField)
        
        // Add UI Components
//        addLocationField(to: container)
        addPrioritySegmentedControl(to: container)
        addAllDaySwitch(to: container)
        addDatePickers(to: container)
        addDurationToggle(to: container, durationPickers: &durationPickers)
        addRecurrenceSelector(to: container, viewController: self)
        addAllowSplittingSwitch(to: container)
        addAllowOverlapSwitch(to: container)
        addNoteTextField(to: container)
    }
    
    // Add Location Field
    func addLocationField(to container: UIStackView) {
        let locationTextField = UITextField()
        locationTextField.placeholder = "Enter location"
        locationTextField.borderStyle = .roundedRect
        container.addArrangedSubview(locationTextField)
    }

    // Add Priority Segmented Control
    func addPrioritySegmentedControl(to container: UIStackView) {
        let priorityContainer = UIStackView()
        priorityContainer.axis = .horizontal
        priorityContainer.spacing = 10
        
        let priorityLabel = UILabel()
        priorityLabel.text = "Priority"
        priorityLabel.font = .systemFont(ofSize: 16, weight: .medium)
        priorityContainer.addArrangedSubview(priorityLabel)
        
        let prioritySegmentedControl = UISegmentedControl(items: ["High", "Medium", "Low"])
        prioritySegmentedControl.selectedSegmentIndex = 1 // Default to Medium
        priorityContainer.addArrangedSubview(prioritySegmentedControl)
        
        container.addArrangedSubview(priorityContainer)
    }

    // Add All-Day Switch
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

    // Add Date Pickers
    func addDatePickers(to container: UIStackView) {
        let now = Date()
        
        // Start Date Picker
        let startContainer = UIStackView()
        startContainer.axis = .horizontal
        startContainer.spacing = 10
        
        let startLabel = UILabel()
        startLabel.text = "Starts"
        startLabel.font = .systemFont(ofSize: 16, weight: .medium)
        startContainer.addArrangedSubview(startLabel)
        
        let startDatePicker = UIDatePicker()
        startDatePicker.datePickerMode = .dateAndTime
        startDatePicker.minimumDate = now
        startDatePicker.addTarget(self, action: #selector(startDateChanged(_:)), for: .valueChanged)
        startContainer.addArrangedSubview(startDatePicker)
        container.addArrangedSubview(startContainer)
        
        // End Date Picker
        let endContainer = UIStackView()
        endContainer.axis = .horizontal
        endContainer.spacing = 10
        
        let endLabel = UILabel()
        endLabel.text = "Ends"
        endLabel.font = .systemFont(ofSize: 16, weight: .medium)
        endContainer.addArrangedSubview(endLabel)
        
        let endDatePicker = UIDatePicker()
        endDatePicker.datePickerMode = .dateAndTime
        endDatePicker.minimumDate = now
        endDatePicker.addTarget(self, action: #selector(endDateChanged(_:)), for: .valueChanged)
        endContainer.addArrangedSubview(endDatePicker)
        container.addArrangedSubview(endContainer)
    }

    // Add Duration Toggle
    func addDurationToggle(to container: UIStackView, durationPickers: inout [UIStackView: UIDatePicker]) {
        let durationToggleContainer = UIStackView()
        durationToggleContainer.axis = .horizontal
        durationToggleContainer.spacing = 10
        
        let durationLabel = UILabel()
        durationLabel.text = "Add Duration"
        durationLabel.font = .systemFont(ofSize: 16, weight: .medium)
        durationToggleContainer.addArrangedSubview(durationLabel)
        
        let durationSwitch = UISwitch()
        durationSwitch.isOn = false
        durationSwitch.addTarget(self, action: #selector(durationSwitchToggled(_:)), for: .valueChanged)
        durationToggleContainer.addArrangedSubview(durationSwitch)
        container.addArrangedSubview(durationToggleContainer)
        
        let picker = UIDatePicker()
        picker.datePickerMode = .countDownTimer
        picker.countDownDuration = 3600 // Default to 1 hour (3600 seconds)
        picker.isHidden = true
        picker.addTarget(self, action: #selector(durationPickerChanged(_:)), for: .valueChanged)
        container.addArrangedSubview(picker)
        
        durationPickers[container] = picker
    }

    // Add Recurrence Selector
    func addRecurrenceSelector(to container: UIStackView, viewController: UIViewController) {
        let recurrenceContainer = UIStackView()
        recurrenceContainer.axis = .horizontal
        recurrenceContainer.spacing = 10
        
        let recurrenceLabel = UILabel()
        recurrenceLabel.text = "Repeats"
        recurrenceLabel.font = .systemFont(ofSize: 16, weight: .medium)
        recurrenceContainer.addArrangedSubview(recurrenceLabel)
        
        let recurrenceButton = UIButton(type: .system)
        recurrenceButton.setTitle("Never", for: .normal)
        recurrenceButton.tintColor = .darkGray
        
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: "chevron.down")
        config.imagePlacement = .trailing
        config.imagePadding = 2
        recurrenceButton.configuration = config
        
        recurrenceButton.addTarget(viewController, action: #selector(AddEventViewController.showRecurrenceOptions(_:)), for: .touchUpInside)
        recurrenceContainer.addArrangedSubview(recurrenceButton)
        container.addArrangedSubview(recurrenceContainer)
    }

    // Add Note Text Field
    func addNoteTextField(to container: UIStackView) {
        let noteContainer = UIStackView()
        noteContainer.axis = .vertical
        noteContainer.spacing = 8
        
        let noteLabel = UILabel()
        noteLabel.text = "Add a Note"
        noteLabel.font = .systemFont(ofSize: 16, weight: .medium)
        
        let noteTextField = UITextField()
        noteTextField.placeholder = "Enter note"
        noteTextField.borderStyle = .roundedRect
        noteContainer.addArrangedSubview(noteLabel)
        noteContainer.addArrangedSubview(noteTextField)
        container.addArrangedSubview(noteContainer)
    }

    // Add Allow Splitting Switch
    func addAllowSplittingSwitch(to container: UIStackView) {
        let splittingSwitchContainer = UIStackView()
        splittingSwitchContainer.axis = .horizontal
        splittingSwitchContainer.spacing = 10
        
        let splittingLabel = UILabel()
        splittingLabel.text = "Allow Splitting"
        splittingLabel.font = .systemFont(ofSize: 16, weight: .medium)
        splittingSwitchContainer.addArrangedSubview(splittingLabel)
        
        let splittingSwitch = UISwitch()
        splittingSwitchContainer.addArrangedSubview(splittingSwitch)
        container.addArrangedSubview(splittingSwitchContainer)
    }

    // Add Allow Overlap Switch
    func addAllowOverlapSwitch(to container: UIStackView) {
        let overlapSwitchContainer = UIStackView()
        overlapSwitchContainer.axis = .horizontal
        overlapSwitchContainer.spacing = 10
        
        let overlapLabel = UILabel()
        overlapLabel.text = "Allow Overlap"
        overlapLabel.font = .systemFont(ofSize: 16, weight: .medium)
        overlapSwitchContainer.addArrangedSubview(overlapLabel)
        
        let overlapSwitch = UISwitch()
        overlapSwitchContainer.addArrangedSubview(overlapSwitch)
        container.addArrangedSubview(overlapSwitchContainer)
    }

    // MARK: - Event Handlers
    @objc func allDaySwitchToggled(_ sender: UISwitch) {
        guard let container = sender.superview?.superview as? UIStackView else { return }
        let datePickers = container.arrangedSubviews
            .compactMap { $0 as? UIStackView }
            .flatMap { $0.arrangedSubviews }
            .compactMap { $0 as? UIDatePicker }

        for picker in datePickers {
            picker.datePickerMode = sender.isOn ? .date : .dateAndTime
        }
    }

    @objc func startDateChanged(_ sender: UIDatePicker) {
        guard let container = sender.superview?.superview as? UIStackView else { return }
        let durationPicker = durationPickers[container]

        // Explicitly locate the end date picker by its associated label
        guard let endDatePicker = findDatePicker(in: container, withLabel: "Ends") else {
            print("End date picker not found")
            return
        }

        if let durationPicker = durationPicker, !durationPicker.isHidden {
            // Adjust the end date based on the start date + duration
            let requiredEndDate = sender.date.addingTimeInterval(durationPicker.countDownDuration)
            if endDatePicker.date < requiredEndDate {
                endDatePicker.date = requiredEndDate
            }
            endDatePicker.minimumDate = requiredEndDate
        } else {
            // No duration picker active; ensure end date is at least the start date
            if sender.date > endDatePicker.date {
                endDatePicker.date = sender.date
            }
            endDatePicker.minimumDate = sender.date
        }
        print("Updated end date to: \(endDatePicker.date)")
    }


    @objc func endDateChanged(_ sender: UIDatePicker) {
        print("End date changed to: \(sender.date)")
        guard let container = sender.superview?.superview as? UIStackView else { return }
        let startDatePicker = container.arrangedSubviews
            .compactMap { ($0 as? UIStackView)?.arrangedSubviews.first as? UIDatePicker }
            .first
        let durationPicker = durationPickers[container]

        if let startDatePicker = startDatePicker, let durationPicker = durationPicker, !durationPicker.isHidden {
            // Ensure end date accounts for start date + duration
            let requiredEndDate = startDatePicker.date.addingTimeInterval(durationPicker.countDownDuration)
            if sender.date < requiredEndDate {
                sender.date = requiredEndDate
            }
        }
    }


    @objc func durationPickerChanged(_ sender: UIDatePicker) {
        guard let container = durationPickers.first(where: { $1 == sender })?.key else { return }

        let startDatePicker = findDatePicker(in: container, withLabel: "Starts")
        let endDatePicker = findDatePicker(in: container, withLabel: "Ends")

        if let startDatePicker = startDatePicker, let endDatePicker = endDatePicker {
            let newEndDate = startDatePicker.date.addingTimeInterval(sender.countDownDuration)
            endDatePicker.setDate(newEndDate, animated: true)
            endDatePicker.minimumDate = newEndDate
            print("Updated end date based on duration to: \(newEndDate)")
        } else {
            print("Failed to locate start or end date picker")
        }
    }


    @objc func durationSwitchToggled(_ sender: UISwitch) {
        guard let container = sender.superview?.superview as? UIStackView,
              let picker = durationPickers[container] else { return }
        
        picker.isHidden = !sender.isOn

        if sender.isOn {
            if let startDatePicker = findDatePicker(in: container, withLabel: "Starts"),
               let endDatePicker = findDatePicker(in: container, withLabel: "Ends") {

                // Immediately adjust the end date when duration toggle is enabled
                let requiredEndDate = startDatePicker.date.addingTimeInterval(picker.countDownDuration)
                endDatePicker.setDate(requiredEndDate, animated: true)
                endDatePicker.minimumDate = requiredEndDate
                
                // Find the scroll view by traversing up the view hierarchy
                var currentView = container as UIView
                var scrollView: UIScrollView?
                
                while currentView.superview != nil {
                    if let foundScrollView = currentView.superview as? UIScrollView {
                        scrollView = foundScrollView
                        break
                    }
                    currentView = currentView.superview!
                }
                
                // Ensure we found the scroll view and handle the scrolling
                if let scrollView = scrollView {
                    // Force layout update
                    scrollView.layoutIfNeeded()
                    container.layoutIfNeeded()
                    
                    // Convert container's frame to scroll view's coordinate space
                    let containerRect = container.convert(container.bounds, to: scrollView)
                    let bottomOfContainer = containerRect.maxY // Add padding
                    
                    // Calculate new offset
                    let newOffset = bottomOfContainer - scrollView.bounds.height
                    if newOffset > scrollView.contentOffset.y {
                        DispatchQueue.main.async {
                            scrollView.setContentOffset(CGPoint(x: 0, y: newOffset), animated: true)
                        }
                    }
                }
            }
        }
    }


    @objc func showRecurrenceOptions(_ sender: UIButton) {
        let alertController = UIAlertController(title: "Repeat", message: nil, preferredStyle: .actionSheet)
        let options = ["Never", "Daily", "Weekly", "Monthly", "Yearly"]

        for option in options {
            alertController.addAction(UIAlertAction(title: option, style: .default) { _ in
                sender.setTitle(option, for: .normal)
            })
        }

        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        if let popover = alertController.popoverPresentationController {
            popover.sourceView = sender
            popover.sourceRect = sender.bounds
        }
        present(alertController, animated: true)
    }
    
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
    
    // MARK: - Helper to Build Custom Event
    /// Builds a new CustomEvent from the input fields.
    /// If required fields are missing, it animates the title field and shows an alert.
    func buildCustomEventFromInput() -> CustomEvent? {
        guard let container = stackView.arrangedSubviews.first as? UIStackView,
              Auth.auth().currentUser != nil else {
            print("Error: Could not find container or user not authenticated")
            return nil
        }
        
        // Get the title field.
        guard let titleField = container.arrangedSubviews.first(where: { $0 is UITextField }) as? UITextField else {
            return nil
        }
        if titleField.text?.isEmpty ?? true {
            titleField.layer.borderWidth = 1.5
            titleField.layer.borderColor = UIColor.systemRed.cgColor
            titleField.layer.cornerRadius = 5.0
            
            let animation = CABasicAnimation(keyPath: "borderColor")
            animation.fromValue = UIColor.clear.cgColor
            animation.toValue = UIColor.systemRed.cgColor
            animation.duration = 0.3
            titleField.layer.add(animation, forKey: "borderColor")
            
            showAlert(title: "Missing Information", message: "Please fill in all required fields.")
            return nil
        }
        titleField.layer.borderWidth = 0
        
        let startDatePicker = findDatePicker(in: container, withLabel: "Starts")
        let endDatePicker = findDatePicker(in: container, withLabel: "Ends")
        
        // Get optional switches and note field.
        let allDaySwitch = container.arrangedSubviews
            .compactMap { $0 as? UIStackView }
            .first(where: { stack in stack.arrangedSubviews.contains { ($0 as? UILabel)?.text == "All-day" } })?
            .arrangedSubviews.compactMap { $0 as? UISwitch }.first
        
        let noteField = (container.arrangedSubviews.first(where: { subview in
            if let sv = subview as? UIStackView {
                return sv.arrangedSubviews.contains { ($0 as? UILabel)?.text == "Add a Note" }
            }
            return false
        }) as? UIStackView)?.arrangedSubviews.last as? UITextField
        
        let durationPicker = durationPickers[container]
        
        let allowSplitSwitch = container.arrangedSubviews
            .compactMap { $0 as? UIStackView }
            .first(where: { stack in stack.arrangedSubviews.contains { ($0 as? UILabel)?.text == "Allow Splitting" } })?
            .arrangedSubviews.compactMap { $0 as? UISwitch }.first
        
        let allowOverlapSwitch = container.arrangedSubviews
            .compactMap { $0 as? UIStackView }
            .first(where: { stack in stack.arrangedSubviews.contains { ($0 as? UILabel)?.text == "Allow Overlap" } })?
            .arrangedSubviews.compactMap { $0 as? UISwitch }.first
        
        let priorityControl = container.arrangedSubviews
            .compactMap { $0 as? UIStackView }
            .first(where: { stack in stack.arrangedSubviews.contains { ($0 as? UILabel)?.text == "Priority" } })?
            .arrangedSubviews.compactMap { $0 as? UISegmentedControl }.first
        
        // Ensure required fields exist.
        guard let title = titleField.text, !title.isEmpty,
              let startDate = startDatePicker?.date,
              let endDate = endDatePicker?.date
        else {
            return nil
        }
        
        let isAllDay = allDaySwitch?.isOn ?? false
        let allowSplit = allowSplitSwitch?.isOn ?? false
        let allowOverlap = allowOverlapSwitch?.isOn ?? false
        let duration = (durationPicker?.isHidden == false) ? Int(durationPicker?.countDownDuration ?? 0) : Int(endDate.timeIntervalSince(startDate))
        let descriptionText = noteField?.text ?? ""
        
        let priority: CustomEvent.Priority = {
            guard let index = priorityControl?.selectedSegmentIndex else { return .medium }
            switch index {
            case 0: return .high
            case 1: return .medium
            case 2: return .low
            default: return .medium
            }
        }()
        
        let customEvent = CustomEvent(
            title: title,
            date: startDate, // Using the start date as the event date.
            startTime: startDate,
            endTime: endDate,
            duration: duration,
            description: [descriptionText],
            isRecurring: false,
            daysOfWeek: nil,
            isAllDay: isAllDay,
            allowSplit: allowSplit,
            allowOverlap: allowOverlap,
            priority: priority
        )
        return customEvent
    }

    func fetchExistingEvents(completion: @escaping ([CustomEvent]) -> Void) {
        guard let userID = Auth.auth().currentUser?.uid else {
            completion([])
            return
        }
        
        let db = Firestore.firestore()
        db.collection("userEvents").document(userID).collection("events").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching documents: \(error)")
                completion([])
                return
            }
            
            var events = [CustomEvent]()
            for document in snapshot!.documents {
                let data = document.data()
                
                // Manually extract fields from Firestore data:
                let title = data["title"] as? String ?? "No Title"
                let startTimestamp = data["startTime"] as? Timestamp
                let endTimestamp = data["endTime"] as? Timestamp
                let dateTimestamp = data["date"] as? Timestamp
                let duration = data["duration"] as? Int ?? 0
                let isRecurring = data["isRecurring"] as? Bool ?? false
                let daysOfWeek = data["daysOfWeek"] as? [String: Bool]
                let isAllDay = data["isAllDay"] as? Bool ?? false
                let allowSplit = data["allowSplit"] as? Bool ?? false
                let allowOverlap = data["allowOverlap"] as? Bool ?? false
                
                // Convert priority string to enum.
                let priorityString = data["priority"] as? String ?? "medium"
                let priority: CustomEvent.Priority = {
                    switch priorityString.lowercased() {
                    case "high": return .high
                    case "low": return .low
                    default: return .medium
                    }
                }()
                
                // Convert Timestamps to Date
                let startTime = startTimestamp?.dateValue()
                let endTime = endTimestamp?.dateValue()
                let date = dateTimestamp?.dateValue()
                let description = data["description"] as? String ?? ""
                
                let event = CustomEvent(
                    title: title,
                    date: date ?? startTime ?? Date(),
                    startTime: startTime,
                    endTime: endTime,
                    duration: duration,
                    description: [description],  // Wrap the description in an array.
                    isRecurring: isRecurring,
                    daysOfWeek: daysOfWeek,
                    isAllDay: isAllDay,
                    allowSplit: allowSplit,
                    allowOverlap: allowOverlap,
                    priority: priority
                )
                events.append(event)
                
                print("Fetched event: \(title) from \(String(describing: startTime)) to \(String(describing: endTime))")
            }
            completion(events)
        }
    }

    // MARK: - Save Event Logic
    @objc func saveEvent() {
        guard validateEventData() else { return }
        
        // Build the new event using your helper.
        guard let newEvent = buildCustomEventFromInput() else {
            // An alert is already shown in the helper.
            return
        }
        
        // Fetch existing events from Firebase.
        fetchExistingEvents { [weak self] existingEvents in
            guard let self = self else { return }
            if self.hasConflict(newEvent: newEvent, existingEvents: existingEvents) {
                print("Conflict detected. Calling AI conflict resolver...")
                let hud = self.showConflictResolutionHUD()
                let openAIClient = OpenAIAPIClient(apiKey: Config.openAIToken)
                let optimizer = ScheduleOptimizer(openAIClient: openAIClient)
                
                Task {
                    do {
                        // Our resolver now returns candidate solutions directly.
                        let candidateSolutions = try await optimizer.resolveConflicts(existingEvents: existingEvents, newEvent: newEvent)
                        
                        // Remove duplicates.
                        // We assume that each candidate solution contains an event matching the new event's title.
                        var uniqueCandidates: [[CustomEvent]] = []
                        var seenKeys = Set<String>()
                        let dateFormatter = DateFormatter()
                        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ" // ISO format for comparison
                        
                        for candidate in candidateSolutions {
                            if let candidateEvent = candidate.first(where: { $0.title == newEvent.title }),
                               let startTime = candidateEvent.startTime,
                               let endTime = candidateEvent.endTime {
                                let key = "\(dateFormatter.string(from: startTime))-\(dateFormatter.string(from: endTime))"
                                if !seenKeys.contains(key) {
                                    uniqueCandidates.append(candidate)
                                    seenKeys.insert(key)
                                }
                            }
                        }
                        
                        await MainActor.run {
                            hud.dismiss(animated: true, completion: {
                                if uniqueCandidates.isEmpty {
                                    self.showAlert(title: "Error", message: "No valid candidate solutions were returned.")
                                } else {
                                    self.presentResolvedSchedule(uniqueCandidates, newEvent: newEvent, conflictingEvents: existingEvents.filter {
                                        guard let newStart = newEvent.startTime, let newEnd = newEvent.endTime,
                                              let eventStart = $0.startTime, let eventEnd = $0.endTime else { return false }
                                        return newStart < eventEnd && newEnd > eventStart
                                    })
                                }
                            })
                        }
                    } catch {
                        await MainActor.run {
                            hud.dismiss(animated: true, completion: {
                                self.showAlert(title: "Resolution Error", message: "Failed to resolve conflicts: \(error.localizedDescription)")
                            })
                        }
                    }
                }
            } else {
                // No conflict: save directly.
                DispatchQueue.main.async {
                    self.saveToFirebase(newEvent: newEvent)
                    self.promptToAddAnotherEvent()
                }
            }
        }
    }




    
    func hasConflict(newEvent: CustomEvent, existingEvents: [CustomEvent]) -> Bool {
        guard let newStart = newEvent.startTime, let newEnd = newEvent.endTime else {
            return false
        }
        for event in existingEvents {
            guard let existingStart = event.startTime, let existingEnd = event.endTime else { continue }
            // If new event starts before an existing event ends
            // and ends after an existing event starts, there is overlap.
            if newStart < existingEnd && newEnd > existingStart {
                return true
            }
        }
        return false
    }


    func validateEventData() -> Bool {
        guard let container = stackView.arrangedSubviews.first as? UIStackView else { return false }
        let startDatePicker = container.arrangedSubviews
            .compactMap { ($0 as? UIStackView)?.arrangedSubviews.first as? UIDatePicker }
            .first
        let endDatePicker = container.arrangedSubviews
            .compactMap { ($0 as? UIStackView)?.arrangedSubviews.last as? UIDatePicker }
            .first

        if let startDate = startDatePicker?.date, let endDate = endDatePicker?.date {
            if endDate < startDate {
                showAlert(title: "Invalid Dates", message: "End date cannot be before start date.")
                return false
            }
        }
        return true
    }


    let notificationManager = UserNotifications()
        
    func saveEventAndScheduleNotification(title: String, startTime: Date, isAllDay: Bool, priority: String) {
        notificationManager.scheduleEventNotification(
            title: title,
            startTime: startTime,
            isAllDay: isAllDay,
            priority: priority
        )
    }

    // MARK: - Modified Save to Firebase
    /// Saves the given event to Firebase.
    func saveToFirebase(newEvent: CustomEvent) {
        guard let userID = Auth.auth().currentUser?.uid else {
            print("Error: User not authenticated")
            return
        }
        let db = Firestore.firestore()
        let eventData: [String: Any] = [
            "title": newEvent.title,
            "date": newEvent.date ?? Date(),
            "startTime": newEvent.startTime ?? Date(),
            "endTime": newEvent.endTime ?? Date(),
            "duration": newEvent.duration,
            "description": newEvent.description.joined(separator: "\n"),
            "isRecurring": newEvent.isRecurring,
            "isAllDay": newEvent.isAllDay,
            "allowSplit": newEvent.allowSplit,
            "allowOverlap": newEvent.allowOverlap,
            "priority": newEvent.priority.rawValue
        ]
        
        let priorityString: String = {
            switch newEvent.priority {
            case .high: return "high"
            case .medium: return "medium"
            case .low: return "low"
            }
        }()
        
        print("Attempting to save event with data:", eventData)
        
        db.collection("userEvents").document(userID).collection("events").addDocument(data: eventData) { [weak self] error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let error = error {
                    print("Error saving event to Firebase:", error)
                    self.showAlert(title: "Error", message: "Failed to save event. Please try again.")
                } else {
                    print("Event saved successfully")
                    //create notification
                    self.saveEventAndScheduleNotification(
                        title: newEvent.title,
                        startTime: newEvent.startTime ?? Date(),
                        isAllDay: newEvent.isAllDay,
                        priority: priorityString
                    )
                    self.resetForm()
                    self.promptToAddAnotherEvent()
                }
            }
        }
    }
    
    /// Presents an alert with an activity indicator to show progress.
    /// Returns the presented alert so you can dismiss it later.
    func showConflictResolutionHUD() -> UIAlertController {
        let hud = UIAlertController(title: "Conflict Detected", message: "Searching for solutions...", preferredStyle: .alert)
        
        // Create and configure an activity indicator.
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.translatesAutoresizingMaskIntoConstraints = false
        indicator.isUserInteractionEnabled = false
        indicator.startAnimating()
        
        hud.view.addSubview(indicator)
        
        // Center the indicator horizontally, and place it near the bottom of the alert.
        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: hud.view.centerXAnchor),
            indicator.bottomAnchor.constraint(equalTo: hud.view.bottomAnchor, constant: -20)
        ])
        
        self.present(hud, animated: true, completion: nil)
        return hud
    }
    
    func presentResolvedSchedule(_ candidateSolutions: [[CustomEvent]], newEvent: CustomEvent, conflictingEvents: [CustomEvent]) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d, yyyy h:mm a"
        
        // Build header with original requested time and a summary of conflicts.
        let originalStart = newEvent.startTime ?? Date()
        let originalEnd = newEvent.endTime ?? Date()
        let originalTime = "Original: \n \(dateFormatter.string(from: originalStart)) – \(dateFormatter.string(from: originalEnd))"
        
        let conflictsDescription = conflictingEvents.map { event in
            if let s = event.startTime, let e = event.endTime {
                return "\(event.title): \(dateFormatter.string(from: s)) – \(dateFormatter.string(from: e))"
            }
            return event.title
        }.joined(separator: "\n")
        
        let headerMessage = "\(originalTime)\nConflicts:\n\(conflictsDescription)"
        
        let alert = UIAlertController(title: "Proposed Solutions", message: headerMessage, preferredStyle: .actionSheet)
        
        for (index, candidate) in candidateSolutions.enumerated() {
            if let candidateEvent = candidate.first(where: { $0.title == newEvent.title }),
               let newStart = candidateEvent.startTime,
               let newEnd = candidateEvent.endTime {
                let optionTitle = "Option \(index+1): \(dateFormatter.string(from: newStart)) – \(dateFormatter.string(from: newEnd))"
                alert.addAction(UIAlertAction(title: optionTitle, style: .default, handler: { _ in
                    self.saveToFirebase(newEvent: candidateEvent)
                    self.promptToAddAnotherEvent()
                }))
            }
        }
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        DispatchQueue.main.async {
            self.present(alert, animated: true)
        }
    }

    // Add this function to reset the title field's appearance when the form is reset
    func resetTitleFieldAppearance() {
        guard let container = stackView.arrangedSubviews.first as? UIStackView,
              let titleField = container.arrangedSubviews.first(where: { $0 is UITextField }) as? UITextField else {
            return
        }
        
        titleField.layer.borderWidth = 0
        titleField.layer.borderColor = nil
    }
    
    // MARK: - Reset Form Logic
    @objc func resetForm() {
        guard let container = stackView.arrangedSubviews.first as? UIStackView else { return }
        
        // Reset title field
        if let titleField = container.arrangedSubviews.first(where: { $0 is UITextField }) as? UITextField {
            titleField.text = ""
        }
        resetTitleFieldAppearance()
        
        // Reset location field
        if let locationField = container.arrangedSubviews.first(where: { ($0 as? UITextField)?.placeholder == "Enter location" }) as? UITextField {
            locationField.text = ""
        }
        
        // Reset priority segmented control
        if let priorityContainer = container.arrangedSubviews.first(where: { ($0 as? UIStackView)?.arrangedSubviews.contains(where: { ($0 as? UILabel)?.text == "Priority" }) == true }) as? UIStackView,
           let priorityControl = priorityContainer.arrangedSubviews.first(where: { $0 is UISegmentedControl }) as? UISegmentedControl {
            priorityControl.selectedSegmentIndex = 1 // Default to Medium
        }
        
        // Reset all-day switch and update date picker modes
        if let allDayContainer = container.arrangedSubviews.first(where: { ($0 as? UIStackView)?.arrangedSubviews.contains(where: { ($0 as? UILabel)?.text == "All-day" }) == true }) as? UIStackView,
           let allDaySwitch = allDayContainer.arrangedSubviews.first(where: { $0 is UISwitch }) as? UISwitch {
            allDaySwitch.isOn = false
            
            // Update date picker modes based on all-day switch
            container.arrangedSubviews
                .compactMap { $0 as? UIStackView }
                .flatMap { $0.arrangedSubviews }
                .compactMap { $0 as? UIDatePicker }
                .forEach { $0.datePickerMode = .dateAndTime }
        }
        
        // Reset date pickers
        let now = Date()
        if let startDatePicker = findDatePicker(in: container, withLabel: "Starts") {
            startDatePicker.setDate(now, animated: true)
            startDatePicker.minimumDate = now
            
            if let endDatePicker = findDatePicker(in: container, withLabel: "Ends") {
                endDatePicker.setDate(now, animated: true)
                endDatePicker.minimumDate = now
            }
        }
        
        // Reset duration switch and picker
        if let durationContainer = container.arrangedSubviews.first(where: { ($0 as? UIStackView)?.arrangedSubviews.contains(where: { ($0 as? UILabel)?.text == "Add Duration" }) == true }) as? UIStackView,
           let durationSwitch = durationContainer.arrangedSubviews.first(where: { $0 is UISwitch }) as? UISwitch {
            durationSwitch.isOn = false
            
            if let durationPicker = durationPickers[container] {
                durationPicker.countDownDuration = 3600 // Reset to 1 hour
                durationPicker.isHidden = true
            }
        }
        
        // Reset recurrence button
        if let recurrenceContainer = container.arrangedSubviews.first(where: { ($0 as? UIStackView)?.arrangedSubviews.contains(where: { ($0 as? UILabel)?.text == "Repeats" }) == true }) as? UIStackView,
           let recurrenceButton = recurrenceContainer.arrangedSubviews.first(where: { $0 is UIButton }) as? UIButton {
            recurrenceButton.setTitle("Never", for: .normal)
        }
        
        // Reset allow splitting switch
        if let splittingContainer = container.arrangedSubviews.first(where: { ($0 as? UIStackView)?.arrangedSubviews.contains(where: { ($0 as? UILabel)?.text == "Allow Splitting" }) == true }) as? UIStackView,
           let splittingSwitch = splittingContainer.arrangedSubviews.first(where: { $0 is UISwitch }) as? UISwitch {
            splittingSwitch.isOn = false
        }
        
        // Reset allow overlap switch
        if let overlapContainer = container.arrangedSubviews.first(where: { ($0 as? UIStackView)?.arrangedSubviews.contains(where: { ($0 as? UILabel)?.text == "Allow Overlap" }) == true }) as? UIStackView,
           let overlapSwitch = overlapContainer.arrangedSubviews.first(where: { $0 is UISwitch }) as? UISwitch {
            overlapSwitch.isOn = false
        }
        
        // Reset note field
        if let noteContainer = container.arrangedSubviews.first(where: { ($0 as? UIStackView)?.arrangedSubviews.contains(where: { ($0 as? UILabel)?.text == "Add a Note" }) == true }) as? UIStackView,
           let noteField = noteContainer.arrangedSubviews.last as? UITextField {
            noteField.text = ""
        }
        
        print("Form reset completed successfully")
    }





    func promptToAddAnotherEvent() {
        let alert = UIAlertController(title: "Event Saved", message: "Would you like to add another event?", preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Yes", style: .default) { [weak self] _ in

        })
        
        alert.addAction(UIAlertAction(title: "No", style: .cancel) { [weak self] _ in
            // Navigate to the first tab
            if let tabBarController = self?.tabBarController {
                tabBarController.selectedIndex = 0
            }
        })
        
        present(alert, animated: true)
    }

    func showAlert(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}
