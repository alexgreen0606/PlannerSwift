//
//  LocationSearchService.swift
//  Planner
//
//  Created by Alex Green on 2/5/26.
//

import Combine
import MapKit
import SwiftUI

@MainActor
class LocationSearchService:
    NSObject,
    ObservableObject,
    MKLocalSearchCompleterDelegate
{
    override init() {
        super.init()
        completer.resultTypes = .address
        completer.delegate = self
    }

    private let completer = MKLocalSearchCompleter()

    @Published var text: String = "" {
        didSet {
            completer.queryFragment = text
        }
    }

    @Published var results: [MKLocalSearchCompletion] = []

    @Published private(set) var noTimeZoneIds = Set<String>()

    @Published var hasNetworkError: Bool = false

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        hasNetworkError = false
        results = completer.results
    }

    func completer(
        _: MKLocalSearchCompleter,
        didFailWithError error: Error
    ) {
        let nsError = error as NSError

        if nsError.domain == NSURLErrorDomain {
            hasNetworkError = true
        } else if nsError.domain == MKError.errorDomain {
            print("ERROR: LocationSearchService.completer: \(error)")
        }
    }

    func locationInfo(for result: MKLocalSearchCompletion) async
        -> Location?
    {
        do {
            if noTimeZoneIds.contains(result.nameId) {
                return nil
            }

            let response = try await MKLocalSearch(
                request: MKLocalSearch.Request(completion: result)
            ).start()

            guard let item = response.mapItems.first else {
                return nil
            }

            // Skip locations that do not have a TimeZone.
            guard let timeZone = item.timeZone
            else {
                noTimeZoneIds.insert(result.nameId)
                return nil
            }

            return Location(
                name: result.title,
                subtitle: result.subtitle,
                latitude: item.location.coordinate.latitude,
                longitude: item.location.coordinate.longitude,
                timeZoneIdentifier: timeZone.identifier
            )
        } catch {
            print("ERROR: LocationSearchService.locationInfo: \(error)")
            return nil
        }
    }
}
