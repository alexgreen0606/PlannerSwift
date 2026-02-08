//
//  LocationSearch.swift
//  Planner
//
//  Created by Alex Green on 2/5/26.
//

import Combine
import MapKit
import SwiftUI

private let starterCities: [Location] = [
    Location(
        name: "Bangkok",
        subtitle: "Thailand",
        latitude: 13.7537858,
        longitude: 100.4985251
    ),
    Location(
        name: "Jakarta",
        subtitle: "Indonesia",
        latitude: -6.2129222,
        longitude: 106.8487229
    ),
    Location(
        name: "London",
        subtitle: "England",
        latitude: 51.5033768,
        longitude: -0.0795183
    ),
    Location(
        name: "Mexico City",
        subtitle: "Mexico",
        latitude: 19.4309037,
        longitude: -99.133595
    ),
    Location(
        name: "Moscow",
        subtitle: "Russia",
        latitude: 55.7586642,
        longitude: 37.6192919
    ),
    Location(
        name: "New York, NY",
        subtitle: "United States",
        latitude: 40.7129822,
        longitude: -74.007205
    ),
    Location(
        name: "Paris",
        subtitle: "France",
        latitude: 48.8567879,
        longitude: 2.3510768
    ),
    Location(
        name: "São Paulo",
        subtitle: "Brazil",
        latitude: -23.5796404,
        longitude: -46.6550645
    ),
    Location(
        name: "Seoul",
        subtitle: "South Korea",
        latitude: 37.5669826,
        longitude: 126.9782352
    ),
    Location(
        name: "Shanghai",
        subtitle: "China",
        latitude: 31.2203102,
        longitude: 121.4623931
    ),
    Location(
        name: "Tokyo",
        subtitle: "Japan",
        latitude: 35.689506,
        longitude: 139.6917
    ),
]

struct LocationSearchView: View {
    let initialLocation: Location?
    @Binding var selected: Location?

    @StateObject private var finder = LocationFinder()
    
    let locationManager = LocationManager.shared

    var body: some View {
        VStack {
            if finder.queryFragment.isEmpty {
                List {
                    Section {
                        ForEach(starterCities, id: \.self) { location in
                            locationRow(
                                title: location.name,
                                subtitle: location.subtitle,
                                isSelected: isLocationSelected(location)
                            ) {
                                selected = selected == location ? nil : location
                            }
                        }
                    } header: {
                        selectionIndicator
                    }
                    .listSectionMargins(.top, 0)
                }
            } else {
                List {
                    Section {
                        ForEach(finder.suggestions, id: \.self) { suggestion in
                            locationRow(
                                title: suggestion.title,
                                subtitle: suggestion.subtitle.isEmpty
                                    ? nil
                                    : suggestion.subtitle,
                                isSelected: isSuggestionSelected(suggestion)
                            ) {
                                Task {
                                    guard
                                        let city =
                                            await finder.selectCompletion(
                                                suggestion
                                            )
                                    else { return }
                                    selected = selected == city ? nil : city
                                }
                            }
                        }
                    } header: {
                        selectionIndicator
                    }
                    .listSectionMargins(.top, 0)
                }
            }
        }
        .background(Color(uiColor: .systemBackground))
        .listStyle(.plain)
        .searchable(
            text: $finder.queryFragment,
            prompt: "Search cities or addresses..."
        )
        .searchPresentationToolbarBehavior(.avoidHidingContent)
    }

    private var selectionIndicator: some View {
        PlannerChipView(
            title: selected?.name ?? "\(locationManager.cityName) (current location)",
            iconName: "location",
            color: Color(uiColor: .label),
            disableInteraction: true
        )
    }

    @ViewBuilder
    private func locationRow(
        title: String,
        subtitle: String?,
        isSelected: Bool,
        onTap: @escaping () -> Void
    ) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)

                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark")
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .discreetListItem()
    }

    private func isLocationSelected(_ location: Location) -> Bool {
        guard let selected else {
            return false
        }

        return selected.latitude == location.latitude
            && selected.longitude == location.longitude
    }

    private func isSuggestionSelected(_ suggestion: MKLocalSearchCompletion)
        -> Bool
    {
        guard let selected else {
            return false
        }

        return selected.name == suggestion.title
            && selected.subtitle == suggestion.subtitle
    }
}
