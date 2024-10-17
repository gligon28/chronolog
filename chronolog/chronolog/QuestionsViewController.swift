//
//  QuestionsViewController.swift
//  chronolog
//
//  Created by Janie Giron on 9/22/24.
//

import UIKit
import FirebaseAuth
import Firebase
import FirebaseFirestore

class QuestionsViewController: UIViewController {

    var activity: Activity!
    var remainingActivities: [Activity] = []
    var currentQuestionIndex = 0
    var answers: [String: Any] = [:] // Dictionary to store answers
    var hasAnsweredInitialQuestions: Bool = false

    
    //@IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var lblActivity: UILabel!
    @IBOutlet weak var lblQuestion: UILabel!
    @IBOutlet weak var txtAnswer: UITextField!
    @IBOutlet weak var stkMultipleSelectionView: UIStackView!
    @IBOutlet weak var hourMinPicker: UIDatePicker!
    
    var multipleSelectionButtons: [UIButton] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        displayQuestion()
    }
    

    func displayQuestion() {
        lblActivity.text = activity.name
        let currentQuestion = activity.questions[currentQuestionIndex]
        lblQuestion.text = currentQuestion.text
            
        // Determine the input type for the current question
        if currentQuestion.text.contains("How many hours") || currentQuestion.text.contains("How much time") {
            txtAnswer.isHidden = true
            hourMinPicker.isHidden = false
            stkMultipleSelectionView.isHidden = true
            hourMinPicker.datePickerMode = .countDownTimer
            hourMinPicker.countDownDuration = 0  // Set the default to 0 hours and 0 minutes

        } else {
            hourMinPicker.isHidden = true
                
            switch currentQuestion.inputType {
            case .text:
                txtAnswer.isHidden = false
                stkMultipleSelectionView.isHidden = true
                txtAnswer.keyboardType = .default
            case .multipleSelection(let options):
                txtAnswer.isHidden = true
                stkMultipleSelectionView.isHidden = false
                setupMultipleSelection(options: options)
            }
        }
    }

    func setupMultipleSelection(options: [String]) {
        stkMultipleSelectionView.arrangedSubviews.forEach { $0.removeFromSuperview() } // Clear previous buttons
        for option in options {
            let button = UIButton(type: .system)
            button.setTitle(option, for: .normal)
            button.addTarget(self, action: #selector(toggleSelection(_:)), for: .touchUpInside)
            button.tag = 0 // 0 = unselected, 1 = selected
            stkMultipleSelectionView.addArrangedSubview(button)
            multipleSelectionButtons.append(button)
        }
    }
    
    @objc func toggleSelection(_ sender: UIButton) {
        sender.tag = sender.tag == 0 ? 1 : 0
        sender.backgroundColor = sender.tag == 1 ? .systemBlue : .clear//Change appearance when selected
    }


    func showAddAnotherPrompt() {
        let alert = UIAlertController(title: "Add Another Entry", message: "Would you like to add another entry for \(activity.name)?", preferredStyle: .alert)
            
        alert.addAction(UIAlertAction(title: "Add Another", style: .default, handler: { _ in
            self.currentQuestionIndex = 0
            self.hasAnsweredInitialQuestions = false
            self.displayQuestion()
        }))
            
        alert.addAction(UIAlertAction(title: "Continue", style: .cancel, handler: { _ in
            if let nextActivity = self.remainingActivities.first {
                // Move to the next activity if there are remaining activities
                let nextRemainingActivities = Array(self.remainingActivities.dropFirst())
                self.navigateToQuestions(for: nextActivity, remainingActivities: nextRemainingActivities)
            } else {
                // Finish the questionnaire if there are no more activities
                self.finishSchedule()
            }
        }))
            
        present(alert, animated: true, completion: nil)
    }
        
    
    @IBAction func btnContinueQuestions(_ sender: UIButton) {
        let currentQuestion = activity.questions[currentQuestionIndex]

        if !hourMinPicker.isHidden {
            let duration = hourMinPicker.countDownDuration
            let hours = Int(duration / 3600)
            let minutes = Int((duration / 60).truncatingRemainder(dividingBy: 60))
            answers[currentQuestion.text] = "\(hours)h \(minutes)m"
        } else {
            switch currentQuestion.inputType {
                case .text:
                    if let answer = txtAnswer.text, !answer.isEmpty {
                        answers[currentQuestion.text] = answer
                    }
                case .multipleSelection:
                    let selectedOptions = multipleSelectionButtons.compactMap { $0.tag == 1 ? $0.titleLabel?.text : nil }
                    answers[currentQuestion.text] = selectedOptions
            }
        }

        txtAnswer.text = ""
        hourMinPicker.isHidden = true
        multipleSelectionButtons.forEach { $0.tag = 0; $0.backgroundColor = .clear }
        saveDataToFirestore()

        if currentQuestionIndex < activity.questions.count - 1 {
            currentQuestionIndex += 1
            displayQuestion()
        } else {
            moveToNextActivityOrFinish()
        }
    }
    
    func moveToNextActivityOrFinish() {
        saveDataToFirestore()
        if let nextActivity = remainingActivities.first {
            let nextRemainingActivities = Array(remainingActivities.dropFirst())
            navigateToQuestions(for: nextActivity, remainingActivities: nextRemainingActivities)
        } else {
            performSegue(withIdentifier: "goToNext", sender: self)
        }
    }
    
    func navigateToQuestions(for activity: Activity, remainingActivities: [Activity]) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let questionsVC = storyboard.instantiateViewController(withIdentifier: "QuestionsViewController") as? QuestionsViewController {
            questionsVC.activity = activity
            questionsVC.remainingActivities = remainingActivities
            navigationController?.pushViewController(questionsVC, animated: true)
        }
    }

    func finishSchedule() {
        print("All questions answered:", answers)
    }
    
    func saveDataToFirestore() {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("Error: User is not authenticated")
            return
        }

        let db = Firestore.firestore()
        // Each user has their own document, and each activity has a document within a subcollection
        let userRef = db.collection("userResponses").document(userId)
        let activityRef = userRef.collection("activities").document(activity.name)

        let dataToSave = [
            "answers": answers,
            "timestamp": FieldValue.serverTimestamp()
        ] as [String : Any]

        activityRef.setData(dataToSave, merge: true) { error in
            if let error = error {
                print("Error saving data to Firestore: \(error.localizedDescription)")
            } else {
                print("Data successfully saved to Firestore for activity \(self.activity.name).")
            }
        }
    }
    
    @objc func timePickerChanged(_ sender: UIDatePicker) {
        let duration = sender.countDownDuration
        let hours = Int(duration / 3600)
        let minutes = Int((duration / 60).truncatingRemainder(dividingBy: 60))
        answers[lblQuestion.text!] = "\(hours)h \(minutes)m"
    }


}
