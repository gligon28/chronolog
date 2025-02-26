//
//  SettingsViewController.swift
//  chronolog
//
//  Created by gg ligon on 10/30/24.
//

import UIKit
import FirebaseAuth

class SettingsViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func btnSignOut(_ sender: UIButton) {
        do {
            try Auth.auth().signOut()
            activeUser = nil
            // Navigate back to login screen
            self.performSegue(withIdentifier: "goToLogin3", sender: self)
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
    
}
