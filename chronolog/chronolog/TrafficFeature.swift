//
//  TrafficFeature.swift
//  chronolog
//
//  Created by Janie Giron on 3/6/25.
//

import Foundation
import CoreLocation
import MapKit
import Firebase
import FirebaseAuth
import FirebaseFirestore

enum TravelMode {
    case driving
    case walking
    case transit
    
    var mapKitDirectionsTransportType: MKDirectionsTransportType {
        switch self {
        case .driving:
            return .automobile
        case .walking:
            return .walking
        case .transit:
            return .transit
        }
    }
}

// Model to hold travel time results
struct TravelTimeResult {
    let travelTimeSeconds: Int
    let distanceMeters: Int
    let arrivalDate: Date
    
    // Convenience getters for formatted values
    var formattedTravelTime: String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .short
        return formatter.string(from: TimeInterval(travelTimeSeconds)) ?? "\(travelTimeSeconds) seconds"
    }
    
    var formattedDistance: String {
        let formatter = MeasurementFormatter()
        let measurement = Measurement(value: Double(distanceMeters), unit: UnitLength.meters)
        return formatter.string(from: measurement)
    }
    
    var formattedArrivalTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: arrivalDate)
    }
}

class TravelTimeCalculator {
    
    // Calculate travel time using MapKit
    func calculateTravelTime(
        userLocation: CLLocationCoordinate2D,
        destination: CLLocationCoordinate2D,
        travelMode: TravelMode = .driving,
        completion: @escaping (Result<TravelTimeResult, Error>) -> Void
    ) {
        let sourcePlacemark = MKPlacemark(coordinate: userLocation)
        let destinationPlacemark = MKPlacemark(coordinate: destination)
        
        let sourceMapItem = MKMapItem(placemark: sourcePlacemark)
        let destinationMapItem = MKMapItem(placemark: destinationPlacemark)
        
        let directionsRequest = MKDirections.Request()
        directionsRequest.source = sourceMapItem
        directionsRequest.destination = destinationMapItem
        directionsRequest.transportType = travelMode.mapKitDirectionsTransportType
        
        let directions = MKDirections(request: directionsRequest)
        
        directions.calculate { response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let route = response?.routes.first else {
                completion(.failure(NSError(domain: "TravelTimeCalculatorError", code: 1, userInfo: [NSLocalizedDescriptionKey: "No routes found"])))
                return
            }
            
            let result = TravelTimeResult(
                travelTimeSeconds: Int(route.expectedTravelTime),
                distanceMeters: Int(route.distance),
                arrivalDate: Date().addingTimeInterval(route.expectedTravelTime)
            )
            
            completion(.success(result))
        }
    }
    
    // Calculate travel time to an event location
    func calculateTravelTimeToEvent(
        userLocation: CLLocationCoordinate2D,
        event: CustomEvent,
        travelMode: TravelMode = .driving,
        completion: @escaping (Result<TravelTimeResult, Error>) -> Void
    ) {
        // Check if the event has a location
        guard let locationString = event.location, !locationString.isEmpty else {
            completion(.failure(NSError(domain: "TravelTimeCalculatorError",
                                       code: 2,
                                       userInfo: [NSLocalizedDescriptionKey: "Event has no location specified"])))
            return
        }
        
        // Geocode the location string to get coordinates
        let geocoder = CLGeocoder()
        geocoder.geocodeAddressString(locationString) { placemarks, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let placemark = placemarks?.first,
                  let location = placemark.location?.coordinate else {
                completion(.failure(NSError(domain: "TravelTimeCalculatorError",
                                           code: 3,
                                           userInfo: [NSLocalizedDescriptionKey: "Could not geocode event location"])))
                return
            }
            
            // Now that we have coordinates, use the existing method to calculate travel time
            self.calculateTravelTime(
                userLocation: userLocation,
                destination: location,
                travelMode: travelMode,
                completion: completion
            )
        }
    }
}

class EventTravelNotificationManager {
    private let travelCalculator = TravelTimeCalculator()
    static let shared = EventTravelNotificationManager()
    
    // Check travel time about 1 hour before event starts
    private let notificationThreshold: TimeInterval = 60 * 60
    
    // Buffer time to add to travel duration (5 minutes)
    private let bufferTime: TimeInterval = 5 * 60
    
    func scheduleTravelCheck(for event: CustomEvent) {
        print("⏱️ Started scheduleTravelCheck for event: \(event.title)")
        
        // Verify the event has required properties
        guard let startTime = event.startTime,
              let location = event.location,
              !location.isEmpty else {
            print("❌ Cannot schedule travel check: Event missing start time or location")
            return
        }
        
        print("📍 Event location: \(location)")
        
        // Calculate when to check travel time (1 hour before event)
        let checkTime = startTime.addingTimeInterval(-notificationThreshold)
        let now = Date()
        
        print("⏰ Current time: \(now)")
        print("🗓️ Event start time: \(startTime)")
        print("🔔 Check time (1 hour before): \(checkTime)")
        print("❓ Is check time <= now? \(checkTime <= now)")
        
        // Only do immediate check if check time is in the past
        if checkTime <= now {
            print("⚡ Check time is now or in the past, performing immediate check")
            checkTravelTimeNow(for: event)
            return
        }
        
        // Generate a unique ID for this travel check
        let checkId = generateCheckId(for: event)
        print("🔑 Generated check ID: \(checkId)")
        
        // Store the event info in Firebase for retrieval when notification triggers
        storeEventForTravelCheck(id: checkId, event: event)
        
        // Create and schedule the notification
        scheduleBackgroundCheck(id: checkId, event: event, checkTime: checkTime)
        
        print("✅ Finished scheduleTravelCheck for event: \(event.title)")
    }

    // New method to break out the notification scheduling logic
    private func scheduleBackgroundCheck(id: String, event: CustomEvent, checkTime: Date) {
        print("📱 Setting up background check notification for: \(event.title) at \(checkTime)")
        
        guard let location = event.location, let startTime = event.startTime else {
            print("❌ Missing required event properties for notification")
            return
        }
        
        // Create the notification content
        let content = UNMutableNotificationContent()
        content.title = "Travel Check"
        content.body = "Checking travel time for \(event.title)"
        content.sound = nil
        content.categoryIdentifier = "TRAVEL_CHECK"
        
        // Store the check ID in the notification
        content.userInfo = [
            "checkId": id,
            "eventTitle": event.title,
            "eventLocation": location,
            "eventStartTime": startTime.timeIntervalSince1970
        ]
        
        // Create trigger for checkTime
        let triggerDate = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: checkTime
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        // Create request
        let request = UNNotificationRequest(
            identifier: "travelcheck-\(id)",
            content: content,
            trigger: trigger
        )
        
        // Schedule notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("❌ Error scheduling travel check notification: \(error)")
            } else {
                print("✅ Successfully scheduled travel check for: \(event.title) at \(checkTime)")
            }
        }
    }
    
    // Generate a unique ID for a check
    private func generateCheckId(for event: CustomEvent) -> String {
        guard let startTime = event.startTime else { return UUID().uuidString }
        return "\(event.title.hashValue)-\(startTime.timeIntervalSince1970.hashValue)"
    }
    
    private func storeEventForTravelCheck(id: String, event: CustomEvent) {
        guard let userID = Auth.auth().currentUser?.uid,
              let startTime = event.startTime else {
            print("❌ Failed to store travel check: User not authenticated or event has no start time")
            return
        }
        
        print("👤 User ID: \(userID)")
        print("📅 Event: \(event.title) at \(startTime)")
        
        let db = Firestore.firestore()
        let travelCheckData: [String: Any] = [
            "title": event.title,
            "startTime": Timestamp(date: startTime),
            "location": event.location ?? "",
            "checkTime": Timestamp(date: startTime.addingTimeInterval(-notificationThreshold)),
            "createdAt": Timestamp(date: Date())
        ]
        
        db.collection("userEvents").document(userID).collection("travelChecks").document(id).setData(travelCheckData) { error in
            if let error = error {
                print("❌ Error storing travel check: \(error.localizedDescription)")
                print("❌ Error code: \((error as NSError).code)")
                print("❌ Error domain: \((error as NSError).domain)")
            } else {
                print("✅ Successfully stored travel check for event: \(event.title) with ID: \(id)")
            }
        }
    }
    
    // Check travel time immediately (when app is open)
    func checkTravelTimeNow(for event: CustomEvent) {
        guard let startTime = event.startTime,
              let location = event.location,
              !location.isEmpty else { return }
        
        // Get current location
        LocationManager.shared.getCurrentLocation { [weak self] currentLocation in
            guard let self = self, let currentLocation = currentLocation else {
                print("Failed to get current location")
                return
            }
            
            // Calculate travel time
            self.travelCalculator.calculateTravelTimeToEvent(
                userLocation: currentLocation.coordinate,
                event: event,
                travelMode: .driving
            ) { result in
                switch result {
                case .success(let travelResult):
                    // Determine when user should leave
                    let travelTimeSeconds = TimeInterval(travelResult.travelTimeSeconds)
                    let leaveTime = startTime.addingTimeInterval(-(travelTimeSeconds + self.bufferTime))
                    
                    // Schedule "leave now" notification
                    self.scheduleLeaveNotification(event: event, travelResult: travelResult, leaveTime: leaveTime)
                    
                case .failure(let error):
                    print("Error calculating travel time: \(error)")
                }
            }
        }
    }
    
    // Process a travel check notification that fired (app was closed)
    func processTravelCheckNotification(with userInfo: [AnyHashable: Any]) {
        guard let eventTitle = userInfo["eventTitle"] as? String,
              let eventLocation = userInfo["eventLocation"] as? String,
              let eventStartTimeInterval = userInfo["eventStartTime"] as? TimeInterval else {
            print("Missing required event info in notification")
            return
        }
        
        let eventStartTime = Date(timeIntervalSince1970: eventStartTimeInterval)
        
        // Create a minimal event object from the notification data
        let event = CustomEvent(
            title: eventTitle,
            date: eventStartTime,
            startTime: eventStartTime,
            endTime: eventStartTime.addingTimeInterval(3600), // Default 1 hour duration
            duration: 3600,
            description: [""],
            isRecurring: false,
            daysOfWeek: nil,
            isAllDay: false,
            allowSplit: false,
            allowOverlap: false,
            priority: .medium,
            deadline: nil,
            location: eventLocation
        )
        
        // Since we're processing a notification, check travel time now
        checkTravelTimeNow(for: event)
    }
    
    // Schedule the "time to leave" notification
    private func scheduleLeaveNotification(event: CustomEvent, travelResult: TravelTimeResult, leaveTime: Date) {
        let timeUntilLeave = leaveTime.timeIntervalSinceNow
        
        // If user needs to leave in less than 5 minutes, send immediate notification
        if timeUntilLeave < 300 {
            sendImmediateLeaveAlert(event: event, travelResult: travelResult, leaveBy: leaveTime)
            return
        }
        
        // Otherwise, schedule a notification for the leave time
        let content = UNMutableNotificationContent()
        content.title = "Time to Leave"
        content.body = "Leave now for \(event.title). It will take \(travelResult.formattedTravelTime) to arrive."
        content.sound = .default
        
        // Schedule for 15 minutes before leave time to give user preparation time
        let notificationTime = leaveTime.addingTimeInterval(-15 * 60)
        let timeComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: notificationTime
        )
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: timeComponents, repeats: false)
        
        let request = UNNotificationRequest(
            identifier: "leave-\(event.title)-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling leave notification: \(error)")
            }
        }
    }
    
    // Send immediate alert for leaving now
    private func sendImmediateLeaveAlert(event: CustomEvent, travelResult: TravelTimeResult, leaveBy: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Time to Leave Now"
        content.body = "Leave immediately for \(event.title). It will take \(travelResult.formattedTravelTime) to arrive."
        content.sound = .default
        
        // Use nil trigger for immediate delivery
        let request = UNNotificationRequest(
            identifier: "leave-now-\(event.title)-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // Cancel travel checks for an event (e.g. when event is deleted)
    func cancelTravelChecks(for event: CustomEvent) {
        guard let userID = Auth.auth().currentUser?.uid else { return }
        
        // Generate check ID
        let checkId = generateCheckId(for: event)
        
        // Remove from Firebase
        let db = Firestore.firestore()
        db.collection("userEvents").document(userID).collection("travelChecks").document(checkId).delete()
        
        // Cancel any pending notifications
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: ["travelcheck-\(checkId)"]
        )
    }
}
