//
//  DeviceLocationManager.swift
//  Planner
//
//  Created by Alex Green on 1/2/26.
//

import Combine
import MapKit

// Clean

@MainActor
final class DeviceLocationManager: NSObject, ObservableObject,
    CLLocationManagerDelegate
{

    override init() {
        super.init()

        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.requestWhenInUseAuthorization()
    }

    deinit {
        refreshTask?.cancel()
    }

    @Published var deviceClLocation: CLLocation?
    @Published var deviceLocation: Location?
    
    private let manager = CLLocationManager()
    private var refreshTask: Task<Void, Never>?
    
    func loadDeviceLocation() {
        manager.requestLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            loadDeviceLocation()
            startPeriodicRefresh()
        case .denied, .restricted:
            print("Location access denied or restricted.")
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        guard let latest = locations.last else { return }

        let roundedCoordinate = CLLocationCoordinate2D(
            latitude: latest.coordinate.latitude.roundDecimals(to: 2),
            longitude: latest.coordinate.longitude.roundDecimals(to: 2)
        )

        let roundedLocation = CLLocation(
            coordinate: roundedCoordinate,
            altitude: latest.altitude,
            horizontalAccuracy: latest.horizontalAccuracy,
            verticalAccuracy: latest.verticalAccuracy,
            timestamp: latest.timestamp
        )

        deviceClLocation = roundedLocation

        Task {
            await buildDeviceLocation(clLocation: roundedLocation, coordinate: roundedCoordinate)
        }
    }

    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        print("ERROR DeviceLocationManager:", error)
    }
    
    // MARK: - Helper Functions

    // Runs every 10 minutes.
    private func startPeriodicRefresh() {
        refreshTask = Task { @MainActor in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(600))
                loadDeviceLocation()
            }
        }
    }

    private func buildDeviceLocation(
        clLocation: CLLocation,
        coordinate: CLLocationCoordinate2D
    ) async {
        if let request = MKReverseGeocodingRequest(location: clLocation) {
            do {
                let mapItems = try await request.mapItems
                if let item = mapItems.first,
                    let addressInfo = item.addressRepresentations,
                    let city = addressInfo.cityWithContext
                {
                    deviceLocation = Location(
                        name: city,
                        subtitle: addressInfo.regionName,
                        latitude: coordinate.latitude,
                        longitude: coordinate.longitude,
                        timeZoneIdentifier: TimeZone.current.identifier
                    )
                }
            } catch {
                print("ERROR DeviceLocationManager.buildDeviceLocation:", error)
            }
        }
    }
    
}
