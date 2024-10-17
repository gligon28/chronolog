//
//  HomeViewController.swift
//  chronolog
//
//  Created by Janie Giron on 9/30/24.
//

import UIKit

class HomeViewController: UIViewController {

    @IBOutlet weak var lblWelcome: UILabel!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        lblWelcome.isHidden = true
        
        // Set the label text using the activeUsername variable
        if let username = activeUser {
            lblWelcome.text = "Welcome, \(username)"
        } else {
            lblWelcome.text = "Welcome"
        }
        
        lblWelcome.isHidden = false
    }

}
