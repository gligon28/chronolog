import UIKit
import FirebaseAuth
import FirebaseFirestore

class LoginViewController: UIViewController {

    @IBOutlet weak var txtEmail: UITextField!
    @IBOutlet weak var txtPassword: UITextField!
    @IBOutlet weak var lblError: UILabel!
    
    let db = Firestore.firestore()  // Firestore instance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        txtPassword.isSecureTextEntry = true
    }

    @IBAction func btnLogin(_ sender: UIButton) {
        guard let password = txtPassword.text else { return }
        guard let email = txtEmail.text else { return }
        
        // Sign in using FirebaseAuth
                Auth.auth().signIn(withEmail: email, password: password) { firebaseResult, error in
                    if let e = error {
                        // Show error message if login fails
                        print("Error logging in: \(e.localizedDescription)")
                        self.lblError.text = "Login failed: \(e.localizedDescription)"
                        self.lblError.isHidden = false
                    } else {
                        // Retrieve the username from Firestore after successful login
                        if let uid = firebaseResult?.user.uid {
                            self.db.collection("userResponses").document(uid).getDocument { (document, error) in
                                if let document = document, document.exists {
                                    let data = document.data()
                                    // Set the global activeUser variable with the username from Firestore
                                    activeUser = data?["username"] as? String
                                    print("Username: \(activeUser ?? "")")
                                    self.performSegue(withIdentifier: "goToHome", sender: self)
                                } else {
                                    print("Document does not exist")
                                }
                            }
                        }
                    }
                }
            }
    
    func clearFirebaseCache() {
        // Sign out the user to clear any session-related data
        do {
            try Auth.auth().signOut()
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
        
        // Get the Firestore instance and configure temporary settings
        let db = Firestore.firestore()
        
        // Temporarily disable persistence
        let settings = FirestoreSettings()
        settings.isPersistenceEnabled = false // Temporarily disable persistence
        db.settings = settings
        
        // Re-enable persistence after a short delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let newSettings = FirestoreSettings()
            newSettings.isPersistenceEnabled = true // Enable persistence again
            db.settings = newSettings
        }
    }
    
}
