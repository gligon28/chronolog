//
//  ChecklistViewController.swift
//  chronolog
//
//  Created by gg ligon on 9/22/24.
//

import UIKit

class ChecklistViewController: UITableViewController {

    var activities: [Activity] = [
        Activity(name: "Work", isSelected: false, questions: [
                Question(text: "What days of the week do you work?", inputType: .multipleSelection(options: ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"])),
                Question(text: "How many hours are your shifts?", inputType: .text)
            ]),
        Activity(name: "Exercise", isSelected: false, questions: [
                Question(text: "What days of the week do you exercise?", inputType: .multipleSelection(options: ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"])),
                Question(text: "How much time do you spend doing exercise?", inputType: .text)
            ]),
        Activity(name: "Sleep", isSelected: false, questions: [
                Question(text: "How many hours of sleep do you get?", inputType: .text)
            ]),
        Activity(name: "Commute", isSelected: false, questions: [
                Question(text: "How many hours of commuting do you do?", inputType: .text)
            ]),
        Activity(name: "Meal Planning", isSelected: false, questions: [
                Question(text: "What days of the week do you prepare meals?", inputType: .multipleSelection(options: ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"])),
                Question(text: "How much time do you spend meal prepping", inputType: .text)
            ]),
        Activity(name: "Chores", isSelected: false, questions: [
                Question(text: "What days of the week do you do chores?", inputType: .multipleSelection(options: ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"])),
                Question(text: "How much time do you spend on chores (each day)?", inputType: .text)
            ]),
        Activity(name: "Hobbies", isSelected: false, questions: [
                Question(text: "What is your hobby?", inputType: .text),
                Question(text: "What days of the week do you do this hobby?", inputType: .multipleSelection(options: ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"])),
                Question(text: "How much time do you spend on this hobby each week?", inputType: .text)
            ]),
            
        Activity(name: "Self-Care", isSelected: false, questions: [
                Question(text: "What self-care activity do you do?", inputType: .text),
                Question(text: "What days of the week do you do this self-care activity?", inputType: .multipleSelection(options: ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"])),
                Question(text: "How much time do you spend on this self-care activity?", inputType: .text)
            ]),
        Activity(name: "School", isSelected: false, questions: [
                Question(text: "Add class", inputType: .text),
                Question(text: "What days of the week is the class?", inputType: .multipleSelection(options: ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"])),
                Question(text: "What time?", inputType: .text)
            ]),
            
        Activity(name: "Social Responsibilities", isSelected: false, questions: [
                Question(text: "Enter social responsibility?", inputType: .text),
                Question(text: "What days of the week do you do this social responsibility?", inputType: .multipleSelection(options: ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"])),
                Question(text: "How much time do you spend on this social responsibility?", inputType: .text)
            ])
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Select Schedule Activities"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "ActivityCell")
    }

    
    
    @IBAction func btnContinue(_ sender: UIButton) {
        let selectedActivities = activities.filter { $0.isSelected }
            if let firstActivity = selectedActivities.first {
                navigateToQuestions(for: firstActivity, remainingActivities: Array(selectedActivities.dropFirst()))
            }
        
    }
    
    func navigateToQuestions(for activity: Activity, remainingActivities: [Activity]) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
            if let questionsVC = storyboard.instantiateViewController(withIdentifier: "QuestionsViewController") as? QuestionsViewController {
                questionsVC.activity = activity // Pass the selected activity
                questionsVC.remainingActivities = remainingActivities
                navigationController?.pushViewController(questionsVC, animated: true)
        }
    }


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
        print("\(activities[sender.tag].name) is \(sender.isOn ? "selected" : "deselected")")
    }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
