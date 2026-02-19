//
//  SearchCompleter.swift
//  Planner
//
//  Created by Alex Green on 2/5/26.
//

import Combine
import MapKit
import SwiftUI

@MainActor
class LocationFinder: NSObject, ObservableObject,
    MKLocalSearchCompleterDelegate
{

    override init() {
        super.init()
        completer.resultTypes = .address
        completer.delegate = self
    }

    private let completer = MKLocalSearchCompleter()

    @Published var queryFragment: String = "" {
        didSet {
            completer.queryFragment = queryFragment
        }
    }
    @Published var suggestions: [MKLocalSearchCompletion] = []
    @Published var hasNetworkError: Bool = false

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        hasNetworkError = false
        suggestions = completer.results
    }

    func completer(
        _ completer: MKLocalSearchCompleter,
        didFailWithError error: Error
    ) {
        let nsError = error as NSError

        if nsError.domain == NSURLErrorDomain {
            hasNetworkError = true
        } else if nsError.domain == MKError.errorDomain {
            print("ERROR: LocationFinder.completer: \(error)")
        }
    }

    func selectCompletion(_ completion: MKLocalSearchCompletion) async -> (
        name: String, subtitle: String, latitude: Double, longitude: Double,
        timeZoneIdentifier: String
    )? {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)

        do {
            let response = try await search.start()

            guard let item = response.mapItems.first,
                let timeZoneIdentifier = item.timeZone?.identifier
            else {
                // TODO: Show an error message about not having a timeZone.
                print("ERROR LocationFinder.selectCompletion: Location does not have a timeZone.")
                return nil
            }

            let coordinate = item.location.coordinate

            return (
                name: completion.title,
                subtitle: completion.subtitle,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude,
                timeZoneIdentifier: timeZoneIdentifier
            )

        } catch {
            print("Search error: \(error)")
            return nil
        }
    }

}
