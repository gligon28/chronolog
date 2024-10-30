//
//  ChecklistViewController.swift
//  chronolog
//
//  Created by gg ligon on 9/22/24.
//

import UIKit

class ChecklistViewController: UITableViewController {

    // Define your activities without detailed question data
    var activities: [Activity] = [
        Activity(name: "Work", isSelected: false),
        Activity(name: "Exercise", isSelected: false),
        Activity(name: "Meal Planning", isSelected: false),
        Activity(name: "Chores", isSelected: false),
        Activity(name: "Hobbies", isSelected: false),
        Activity(name: "Self-Care", isSelected: false),
        Activity(name: "School", isSelected: false),
        Activity(name: "Social Responsibilities", isSelected: false),
        Activity(name: "Add Activity", isSelected: false)
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Select Schedule Activities"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ActivityCell")
    }
    
    @IBAction func btnContinue(_ sender: UIButton) {
        // Filter out selected activities only
        let selectedActivities = activities.filter { $0.isSelected }
        // Pass selected activities to the next view controller
        navigateToEventSetup(with: selectedActivities)
    }
    
    func navigateToEventSetup(with selectedActivities: [Activity]) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let questionsVC = storyboard.instantiateViewController(withIdentifier: "QuestionsViewController") as? QuestionsViewController {
            questionsVC.selectedActivities = selectedActivities // Pass selected activities
            navigationController?.pushViewController(questionsVC, animated: true)
        }
    }

    // TableView methods
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return activities.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ActivityCell", for: indexPath)
        cell.textLabel?.text = activities[indexPath.row].name

        let switchControl = UISwitch(frame: .zero)
        switchControl.isOn = activities[indexPath.row].isSelected
        switchControl.tag = indexPath.row
        switchControl.addTarget(self, action: #selector(switchChanged(_:)), for: .valueChanged)
        cell.accessoryView = switchControl
        return cell
    }
    
    @objc func switchChanged(_ sender: UISwitch) {
        activities[sender.tag].isSelected = sender.isOn
//        print("\(activities[sender.tag].name) is \(sender.isOn ? "selected" : "deselected")")
    }
}
