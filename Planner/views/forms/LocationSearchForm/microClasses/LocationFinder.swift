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
    @Published var queryFragment: String = "" {
        didSet { completer.queryFragment = queryFragment }
    }
    @Published var suggestions: [MKLocalSearchCompletion] = []
    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.resultTypes = .address
        completer.delegate = self
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        suggestions = completer.results
    }

    func completer(
        _ completer: MKLocalSearchCompleter,
        didFailWithError error: Error
    ) {
        print("Completer error: \(error)")
    }

    func selectCompletion(_ completion: MKLocalSearchCompletion) async -> (
        name: String, subtitle: String, latitude: Double, longitude: Double
    )? {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)

        do {
            let response = try await search.start()

            guard let item = response.mapItems.first else {
                return nil
            }

            let coordinate = item.location.coordinate

            return (
                name: completion.title,
                subtitle: completion.subtitle,
                latitude: coordinate.latitude,
                longitude: coordinate.longitude
            )

        } catch {
            print("Search error: \(error)")
            return nil
        }
    }

}
