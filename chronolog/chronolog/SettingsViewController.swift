//
//  SettingsViewController.swift
//  chronolog
//
//  Created by gg ligon on 10/30/24.
//

import UIKit
import FirebaseAuth

class SettingsViewController: UITableViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set up the tableView
        tableView.isScrollEnabled = true
        tableView.backgroundColor = UIColor.systemGroupedBackground
        
        // Set title of view controller
        title = "Settings"
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2 // One for Productivity, one for Sign Out
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 3 // Progress Tracking, OtherDestination, AnotherDestination
        } else {
            return 1 // Sign Out cell
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Productivity"
        } else {
            return "Account"
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "SettingsCell") ?? UITableViewCell(style: .default, reuseIdentifier: "SettingsCell")
        
        if indexPath.section == 0 {
            switch indexPath.row {
            case 0:
                cell.textLabel?.text = "Progress Tracking"
            case 1:
                cell.textLabel?.text = "Other Feature"
            case 2:
                cell.textLabel?.text = "Another Feature"
            default:
                cell.textLabel?.text = "Feature"
            }
            cell.accessoryType = .disclosureIndicator
        } else {
            cell.textLabel?.text = "Sign Out"
            cell.textLabel?.textColor = UIColor.systemRed
            cell.accessoryType = .none
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 {
            // Navigate to different destinations based on the row
            switch indexPath.row {
            case 0:
                // Progress Tracking
                if let progressVC = storyboard?.instantiateViewController(withIdentifier: "ProgressTrackingViewController") as? ProgressTrackingViewController {
                    navigationController?.pushViewController(progressVC, animated: true)
                }
            case 1:
                // Some other destination
                if let otherVC = storyboard?.instantiateViewController(withIdentifier: "OtherDestinationViewController") {
                    navigationController?.pushViewController(otherVC, animated: true)
                }
            case 2:
                // Yet another destination
                if let anotherVC = storyboard?.instantiateViewController(withIdentifier: "AnotherDestinationViewController") {
                    navigationController?.pushViewController(anotherVC, animated: true)
                }
            default:
                break
            }
        } else if indexPath.section == 1 {
            // Show confirmation alert before signing out
            let alert = UIAlertController(
                title: "Sign Out",
                message: "Are you sure you want to sign out?",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Sign Out", style: .destructive) { [weak self] _ in
                self?.handleSignOut()
            })
            
            present(alert, animated: true)
        }
    }
    
//    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//            tableView.deselectRow(at: indexPath, animated: true)
//            
//            if indexPath.section == 0 {
//                let progressVC = ProgressTrackingViewController()
//                self.navigationController?.pushViewController(progressVC, animated: true)
//            } else if indexPath.section == 1 {
//                // Show confirmation alert before signing out
//                let alert = UIAlertController(
//                    title: "Sign Out",
//                    message: "Are you sure you want to sign out?",
//                    preferredStyle: .alert
//                )
//                
//                alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
//                alert.addAction(UIAlertAction(title: "Sign Out", style: .destructive) { [weak self] _ in
//                    self?.handleSignOut()
//                })
//                
//                present(alert, animated: true)
//            }
//        }
        
        // MARK: - Navigation
        
        func navigateToProgressTracking() {
            if let progressVC = self.storyboard?.instantiateViewController(withIdentifier: "ProgressTrackingViewController") {
                // For navigation controller push
                if let navController = self.navigationController {
                    print("Using navigation controller to push")
                    navController.pushViewController(progressVC, animated: true)
                } else {
                    print("No navigation controller found, presenting modally")
                    // If no navigation controller, present modally
                    progressVC.modalPresentationStyle = .fullScreen
                    self.present(progressVC, animated: true, completion: nil)
                }
                return
            } else {
                print("Failed to instantiate view controller with ID: ProgressTrackingViewController")
            }
        }
        
        func handleSignOut() {
            do {
                try Auth.auth().signOut()
                activeUser = nil
                
                // Navigate to login screen programmatically
                navigateToLogin()
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
        
        func navigateToLogin() {
            // Get reference to the login view controller from storyboard
            if let loginVC = self.storyboard?.instantiateViewController(withIdentifier: "LoginViewController") {
                // For full screen presentation
                loginVC.modalPresentationStyle = .fullScreen
                
                // For apps using a navigation controller
                if let navigationController = self.navigationController {
                    // Option 1: Pop to root if login is the root
                    navigationController.popToRootViewController(animated: true)
                    
                    // Option 2: Set the view controllers array to just include login
                    // navigationController.setViewControllers([loginVC], animated: true)
                } else {
                    // If no navigation controller, present modally
                    self.present(loginVC, animated: true, completion: nil)
                }
            } else {
                // Fallback if storyboard ID is not found
                // This assumes you have a window reference (iOS 13+ uses scenes)
                if let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate,
                   let window = sceneDelegate.window {
                    // If using a navigation controller as root
                    if let navController = window.rootViewController as? UINavigationController {
                        navController.popToRootViewController(animated: true)
                    } else {
                        // Reset to the app's initial view controller
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        window.rootViewController = storyboard.instantiateInitialViewController()
                        window.makeKeyAndVisible()
                    }
                }
            }
        }
    }
