
import UIKit
import FirebaseAuth

var activeUser = ""

class LoginViewController: UIViewController {

    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func btnLogin(_ sender: UIButton) {
        guard let password = txtPassword.text else { return }
        guard let email = txtEmail.text else { return }
        
        Auth.auth().signIn(withEmail: email, password: password) { firebaseResult, error in
            if let e = error {
                print("error")
            }
            else {
                self.performSegue(withIdentifier: "goToHome", sender: self)
            }
        }

    }
    
    
}

