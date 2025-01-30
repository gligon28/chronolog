//
//  GetToKnowViewController.swift
//  chronolog
//
//  Created by gg ligon on 10/7/24.
//

import UIKit
import FirebaseAuth

class GetToKnowViewController: UIViewController {

    @IBOutlet weak var lblWelcome: UILabel!
    
    @IBAction func btnSignOut(_ sender: UIButton) {
        do {
            try Auth.auth().signOut()
            activeUser = nil
            // Navigate back to login screen
            self.performSegue(withIdentifier: "goToLogin", sender: self)
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
    
    override func viewDidLoad() {
        super.viewDidLoad()

        lblWelcome.isHidden = true
        
        // Set the label text using the activeUsername variable
        if let username = activeUser {
            lblWelcome.text = "Let's Get To Know You, \(username)"
        } else {
            lblWelcome.text = "Let's Get To Know You"
        }
        
        lblWelcome.isHidden = false
    }
    
}
