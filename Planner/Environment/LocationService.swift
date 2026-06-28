//
//  LocationService.swift
//  Planner
//
//  Created by Alex Green on 1/2/26.
//

import Combine
import MapKit

@MainActor
final class LocationService:
    NSObject,
    ObservableObject,
    CLLocationManagerDelegate
{
    override init() {
        super.init()

        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    deinit {
        refreshTask?.cancel()
    }

    private let manager = CLLocationManager()

    private var refreshTask: Task<Void, Never>?

    @Published var deviceClLocation: CLLocation?
    @Published var deviceLocation: Location?

    func loadDeviceLocation() {
        manager.requestLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            loadDeviceLocation()
            scheduleRefresh()
        case .notDetermined:
            manager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            break
        @unknown default:
            break
        }
    }

    func locationManager(
        _: CLLocationManager,
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
            await buildDeviceLocation(
                clLocation: roundedLocation,
                coordinate: roundedCoordinate
            )
        }
    }

    func locationManager(
        _: CLLocationManager,
        didFailWithError error: Error
    ) {
        print("ERROR LocationService:", error)
    }

    // MARK: - Helper Functions

    /// Runs every 10 minutes.
    private func scheduleRefresh() {
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
                print("ERROR LocationService buildDeviceLocation:", error)
            }
        }
    }
}
