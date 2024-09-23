//
//  QuestionsViewController.swift
//  chronolog
//
//  Created by Janie Giron on 9/22/24.
//

import UIKit

class QuestionsViewController: UIViewController {

    var activity: Activity!
    var remainingActivities: [Activity] = []
    var currentQuestionIndex = 0
    var answers: [String: Any] = [:] // Dictionary to store answers

    
    //@IBOutlet weak var questionLabel: UILabel!
    @IBOutlet weak var lblActivity: UILabel!
    @IBOutlet weak var lblQuestion: UILabel!
    @IBOutlet weak var txtAnswer: UITextField!
    @IBOutlet weak var stkMultipleSelectionView: UIStackView!
    
    var multipleSelectionButtons: [UIButton] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        // Display the first question
        displayQuestion()
    }

    func displayQuestion() {
        let currentQuestion = activity.questions[currentQuestionIndex]
        lblQuestion.text = currentQuestion.text
        switch currentQuestion.inputType {
        case .text:
            // Show text input
            txtAnswer.isHidden = false
            stkMultipleSelectionView.isHidden = true
        case .multipleSelection(let options):
            // Show multiple selection (checkboxes or buttons)
            txtAnswer.isHidden = true
            stkMultipleSelectionView.isHidden = false
            setupMultipleSelection(options: options)
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


    @IBAction func btnContinueQuestions(_ sender: UIButton) {
        let currentQuestion = activity.questions[currentQuestionIndex]

        switch currentQuestion.inputType {
            case .text:
                if let answer = txtAnswer.text, !answer.isEmpty {
                    answers[currentQuestion.text] = answer
            }
            case .multipleSelection:
                let selectedOptions = multipleSelectionButtons.compactMap { $0.tag == 1 ? $0.titleLabel?.text : nil }
                answers[currentQuestion.text] = selectedOptions
            }
            // Clear input for next question
            txtAnswer.text = ""
            multipleSelectionButtons.forEach { $0.tag = 0; $0.backgroundColor = .clear }
            // Proceed to next question or activity
            if currentQuestionIndex < activity.questions.count - 1 {
                currentQuestionIndex += 1
                displayQuestion()
            } else {
                if let nextActivity = remainingActivities.first {
                    let nextRemainingActivities = Array(remainingActivities.dropFirst())
                    navigateToQuestions(for: nextActivity, remainingActivities: nextRemainingActivities)
                } else {
                    finishSchedule()
                }
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

}
