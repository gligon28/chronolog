//
//  CreateAccountViewController.swift
//  chronolog
//
//  Created by gg ligon on 9/21/24.
//

import UIKit
import FirebaseAuth

class CreateAccountViewController: UIViewController {

    @IBOutlet weak var txtUsername: UITextField!
    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var txtConfirmPassword: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    @IBAction func btnCreateAccount(_ sender: UIButton) {
        guard let email = txtEmail.text else { return }
        guard let password = txtPassword.text else { return }
        guard let username = txtUsername.text else { return }
        guard let confirmPassword = txtConfirmPassword.text else { return }
        
        Auth.auth().createUser(withEmail: email, password: password) { firebaseResult, error in
            if let e = error {
                print("error")
            }
            else {
                self.performSegue(withIdentifier: "goToNext", sender: self)
            }
        }
    }

    
}
