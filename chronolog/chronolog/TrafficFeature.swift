//
//  TrafficFeature.swift
//  chronolog
//
//  Created by Janie Giron on 3/6/25.
//

import Foundation
import CoreLocation
import MapKit

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

// CustomEvent is imported from another file

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
    
    // Time threshold before event start to check travel time (default 1 hour)
    private let notificationThreshold: TimeInterval = 60 * 60
    
    // Minimum time before event to notify (default 30 minutes)
    private let minimumNotifyTime: TimeInterval = 30 * 60
    
    // Function to setup travel time monitoring for an event
    func monitorTravelTimeForEvent(
        event: CustomEvent,
        userLocationProvider: @escaping () -> CLLocationCoordinate2D?,
        travelMode: TravelMode = .driving
    ) {
        // Verify the event has required properties
        guard let startTime = event.startTime,
              let location = event.location,
              !location.isEmpty else {
            print("Cannot monitor travel time: Event missing start time or location")
            return
        }
        
        // Calculate time until notification check should happen
        let timeUntilCheck = max(0, startTime.timeIntervalSinceNow - notificationThreshold)
        
        // Schedule the travel time check
        DispatchQueue.global().asyncAfter(deadline: .now() + timeUntilCheck) { [weak self] in
            guard let self = self else { return }
            
            // Get current user location when it's time to check
            guard let currentLocation = userLocationProvider() else {
                print("Failed to get user location for travel time calculation")
                return
            }
            
            self.checkAndNotifyTravelTime(
                event: event,
                userLocation: currentLocation,
                travelMode: travelMode
            )
        }
    }
    
    // Check travel time and send notification if needed
    private func checkAndNotifyTravelTime(
        event: CustomEvent,
        userLocation: CLLocationCoordinate2D,
        travelMode: TravelMode
    ) {
        guard let startTime = event.startTime else { return }
        
        travelCalculator.calculateTravelTimeToEvent(
            userLocation: userLocation,
            event: event,
            travelMode: travelMode
        ) { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let travelResult):
                // Determine when user should leave
                let travelTimeSeconds = TimeInterval(travelResult.travelTimeSeconds)
                let bufferTime: TimeInterval = 5 * 60 // 5 minute buffer
                let leaveTime = startTime.addingTimeInterval(-(travelTimeSeconds + bufferTime))
                
                // Check if notification is still relevant (not too late)
                let timeUntilLeave = leaveTime.timeIntervalSinceNow
                if timeUntilLeave < self.minimumNotifyTime {
                    // User should leave soon, notify immediately
                    self.sendImmediateTravelAlert(
                        event: event,
                        travelResult: travelResult,
                        leaveBy: leaveTime
                    )
                } else {
                    // Schedule notification for closer to leave time
                    self.scheduleLeaveTimeNotification(
                        event: event,
                        travelResult: travelResult,
                        leaveTime: leaveTime
                    )
                }
                
            case .failure(let error):
                print("Failed to calculate travel time: \(error.localizedDescription)")
            }
        }
    }
    
    // Send immediate alert if user needs to leave soon
    private func sendImmediateTravelAlert(
        event: CustomEvent,
        travelResult: TravelTimeResult,
        leaveBy: Date
    ) {
        let leaveTimeFormatter = DateFormatter()
        leaveTimeFormatter.dateStyle = .none
        leaveTimeFormatter.timeStyle = .short
        
        let message = """
        Travel alert for "\(event.title)":
        It will take \(travelResult.formattedTravelTime) to reach your destination.
        Leave by \(leaveTimeFormatter.string(from: leaveBy)) to arrive on time.
        """
        
        // Here you would integrate with your notification system
        // This is just a placeholder implementation
        NotificationCenter.default.post(
            name: Notification.Name("ImmediateTravelAlert"),
            object: nil,
            userInfo: [
                "message": message,
                "eventTitle": event.title,
                "travelTime": travelResult.formattedTravelTime,
                "leaveTime": leaveBy
            ]
        )
        
        // Uncomment and modify to use UNUserNotificationCenter
        
        let content = UNMutableNotificationContent()
        content.title = "Time to leave now"
        content.body = message
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "travel-\(event.title)-\(UUID().uuidString)",
            content: content,
            trigger: nil // Immediate notification
        )
        
        UNUserNotificationCenter.current().add(request)
        
    }
    
    // Schedule notification for when user should leave
    private func scheduleLeaveTimeNotification(
        event: CustomEvent,
        travelResult: TravelTimeResult,
        leaveTime: Date
    ) {
        // Schedule notification for 15 minutes before leave time
        let notificationTime = leaveTime.addingTimeInterval(-15 * 60)
        
        // Format the notification content
        let message = """
        Time to prepare for "\(event.title)":
        It will take \(travelResult.formattedTravelTime) to reach your destination.
        You should leave in 15 minutes.
        """
        
        print("Scheduled notification for \(notificationTime): \(message)")
        
        // Uncomment and modify to use UNUserNotificationCenter
        
        let content = UNMutableNotificationContent()
        content.title = "Time to leave soon"
        content.body = message
        content.sound = .default
        
        let timeInterval = notificationTime.timeIntervalSinceNow
        guard timeInterval > 0 else { return }
        
        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: timeInterval,
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: "travel-\(event.title)-\(UUID().uuidString)",
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - Usage Example
/*
// Example of how to use this in your app:

class AppDelegate: UIResponder, UIApplicationDelegate, CLLocationManagerDelegate {
    let locationManager = CLLocationManager()
    let travelNotificationManager = EventTravelNotificationManager()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Set up location manager
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.requestWhenInUseAuthorization()
        
        // Set up notifications
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied: \(error?.localizedDescription ?? "Unknown error")")
            }
        }
        
        return true
    }
    
    // Call this whenever events are loaded or created
    func setupTravelMonitoring(for events: [CustomEvent]) {
        for event in events {
            // Only monitor events with locations
            if let location = event.location, !location.isEmpty {
                travelNotificationManager.monitorTravelTimeForEvent(
                    event: event,
                    userLocationProvider: { [weak self] in
                        return self?.locationManager.location?.coordinate
                    }
                )
            }
        }
    }
}
*/
