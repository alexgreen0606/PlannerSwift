//
//  LocationService.swift
//  Planner
//
//  Created by Alex Green on 1/2/26.
//

import Combine
import MapKit
import SwiftUI

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

    @AppStorage("deviceLocationName") private var deviceLocationName: String = ""
    @AppStorage("deviceLocationTimeZoneId") private var deviceLocationTimeZoneId: String =
        ""

    @Published private(set) var hasAccess: Bool? = nil

    var locationManager: CLLocationManager {
        manager
    }

    var validDeviceLocationName: String {
        guard deviceLocationTimeZoneId == TimeZone.current.identifier else {
            return ""
        }

        return deviceLocationName
    }

    func loadDeviceLocation() {
        manager.requestLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            loadDeviceLocation()
            scheduleRefresh()
            hasAccess = true
            break
        case .notDetermined:
            hasAccess = nil
            break
        case .denied, .restricted:
            hasAccess = false
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

        Task {
            await findDeviceLocationName(
                clLocation: roundedLocation
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

    private func findDeviceLocationName(
        clLocation: CLLocation
    ) async {
        if let request = MKReverseGeocodingRequest(location: clLocation) {
            do {
                let mapItems = try await request.mapItems
                if let item = mapItems.first,
                    let addressInfo = item.addressRepresentations,
                    let city = addressInfo.cityWithContext?.nilIfEmpty
                        ?? addressInfo.cityName,
                   let timeZoneId = item.timeZone?.identifier
                {
                    withAnimation {
                        deviceLocationName = city
                        deviceLocationTimeZoneId = timeZoneId
                    }
                }
            } catch {
                print("ERROR LocationService findDeviceLocationName:", error)
            }
        }
    }
}
