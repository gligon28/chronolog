//
//  GetToKnowViewController.swift
//  chronolog
//
//  Created by gg ligon on 10/7/24.
//

import UIKit

class GetToKnowViewController: UIViewController {

    @IBOutlet weak var lblWelcome: UILabel!
    
    
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
