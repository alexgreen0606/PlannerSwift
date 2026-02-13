//
//  DeviceLocationManager.swift
//  Planner
//
//  Created by Alex Green on 1/2/26.
//

import Combine
import MapKit

@MainActor
final class DeviceLocationManager: NSObject, ObservableObject,
    CLLocationManagerDelegate
{
    
    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    private let manager = CLLocationManager()

    @Published var deviceClLocation: CLLocation?
    @Published var cityName: String?

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let latest = locations.last else { return }
        deviceClLocation = latest

        if let request = MKReverseGeocodingRequest(location: latest) {
            Task {
                do {
                    let mapItems = try await request.mapItems
                    if let item = mapItems.first,
                        let addressInfo = item.addressRepresentations,
                        let city = addressInfo.cityName
                    {
                        cityName = city
                    }
                } catch {
                    print("Failed to get the local city based on this device location:", error)
                }
            }
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        print("LocationManager error:", error)
    }
}
