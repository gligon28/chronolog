//
//  UserNotification.swift
//  chronolog
//
//  Created by Janie Giron on 2/26/25.
//

import UIKit
import UserNotifications
import FirebaseFirestore
import FirebaseAuth

class UserNotifications: NSObject, UNUserNotificationCenterDelegate{

    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error)")
            } else {
                print("Notification permission denied")
            }
        }
    }
    
    func scheduleEventNotification(title: String, startTime: Date, isAllDay: Bool, priority: String) {
        // Request permission and set delegate first
        UNUserNotificationCenter.current().delegate = self
        
        // Request permission and only schedule if granted
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                // Move the notification scheduling code inside the authorization completion handler
                DispatchQueue.main.async {
                    let content = UNMutableNotificationContent()
                    content.title = title
                    
                    if isAllDay {
                        content.body = "You have an all-day event today: \(title)"
                    } else {
                        content.body = "Upcoming event: \(title) at \(self.formatTime(startTime))"
                    }
                    
                    switch priority.lowercased() {
                    case "high":
                        content.body += " (High Priority)"
                        content.sound = UNNotificationSound.defaultCritical
                    case "low":
                        content.sound = UNNotificationSound.default
                    default: // medium
                        content.sound = UNNotificationSound.default
                    }
                    
                    // Rest of your existing notification scheduling code...
                    var notificationTimes: [(TimeInterval, String)] = []
                    
                    if isAllDay {
                        if let midnight = Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: startTime) {
                            let timeUntilMidnight = midnight.timeIntervalSince(Date())
                            if timeUntilMidnight > 0 {
                                notificationTimes.append((timeUntilMidnight, "allDay"))
                            }
                        }
                    } else {
                        let timeUntilStart = startTime.timeIntervalSince(Date())
                        
                        if timeUntilStart > 86400 {
                            notificationTimes.append((timeUntilStart - 86400, "1day"))
                        }
                        
                        if timeUntilStart > 3600 {
                            notificationTimes.append((timeUntilStart - 3600, "1hour"))
                        }
                        
                        if timeUntilStart > 900 {
                            notificationTimes.append((timeUntilStart - 900, "15min"))
                        }
                    }
                    
                    for (timeInterval, identifier) in notificationTimes {
                        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
                        let request = UNNotificationRequest(
                            identifier: "event-\(title)-\(identifier)",
                            content: content,
                            trigger: trigger
                        )
                        
                        UNUserNotificationCenter.current().add(request) { error in
                            if let error = error {
                                print("Error scheduling notification: \(error)")
                            } else {
                                print("Scheduled notification for '\(title)' in \(timeInterval) seconds")
                            }
                        }
                    }
                }
            } else if let error = error {
                print("Notification permission error: \(error)")
            } else {
                print("Notification permission denied")
            }
        }
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                              willPresent notification: UNNotification,
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .list, .sound])
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
