//
//  CreateAccountViewController.swift
//  chronolog
//
//  Created by gg ligon on 9/21/24.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

var activeUser: String?

class CreateAccountViewController: UIViewController {

    @IBOutlet weak var txtUsername: UITextField!
    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var txtConfirmPassword: UITextField!
    @IBOutlet weak var lblError: UILabel!
    
    let db = Firestore.firestore()  // Firestore instance
    
    override func viewDidLoad() {
        super.viewDidLoad()

        lblError.isHidden = true
    }
    
    @IBAction func btnCreateAccount(_ sender: UIButton) {
        guard let email = txtEmail.text else { return }
        guard let password = txtPassword.text else { return }
        guard let username = txtUsername.text else { return }
        guard let confirmPassword = txtConfirmPassword.text, !confirmPassword.isEmpty else { return }
        
        // Check if passwords match
        if password != confirmPassword {
            // Show error message if passwords don't match
            lblError.text = "Passwords do not match."
            lblError.isHidden = false
            return
        }
        
        // Create the account using FirebaseAuth
        Auth.auth().createUser(withEmail: email, password: password) { firebaseResult, error in
            if let e = error {
                // Show error message if there's an error during account creation
                self.lblError.text = "Error creating account: \(e.localizedDescription)"
                self.lblError.isHidden = false
            } else {
                // Set the global activeUser when account creation is successful
                activeUser = username

                // If successful, store the email and username in Firestore
                if let uid = firebaseResult?.user.uid {
                    self.db.collection("userResponses").document(uid).setData([
                        "email": email,
                        "username": username
                    ], merge: true) { err in
                        if let err = err {
                            print("Error writing document: \(err)")
                        } else {
                            print("Document successfully written!")
                            // Hide the error label and perform the segue
                            self.lblError.isHidden = true
                            self.performSegue(withIdentifier: "goToNext", sender: self)
                        }
                    }
                }
            }
        }
    }
}
