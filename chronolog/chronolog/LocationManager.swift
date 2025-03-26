//
//  LocationManager.swift
//  chronolog
//
//  Created by Janie Giron on 3/7/25.

import Foundation
import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    
    private let locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var authorizationStatus: CLAuthorizationStatus {
        return locationManager.authorizationStatus
    }
    
    private override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        startUpdatingLocation()
    }
    
    func startUpdatingLocation() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
            print("Started updating location")
        } else {
            print("Location services are disabled")
        }
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    func getCurrentLocation(completion: @escaping (CLLocation?) -> Void) {
        // If we already have a recent location, use it
        if let currentLocation = currentLocation,
           Date().timeIntervalSince(currentLocation.timestamp) < 60 { // Less than a minute old
            completion(currentLocation)
            return
        }
        
        // Otherwise, request a fresh location
        let locationCompletionHandler: ((CLLocation?) -> Void) = completion
        
        // Set up a one-time location request
        locationManager.requestLocation() // This will call didUpdateLocations once
        
        // Add a timeout in case location can't be determined quickly
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if self.currentLocation == nil {
                locationCompletionHandler(nil)
            } else {
                locationCompletionHandler(self.currentLocation)
            }
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        print("Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to get location: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        print("Location authorization status changed to: \(status.rawValue)")
        
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            startUpdatingLocation()
        default:
            print("Location authorization not granted")
        }
    }
}
