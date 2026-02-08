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

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @StateObject private var finder = LocationFinder()

    let locationManager = LocationManager.shared

    var body: some View {
        List {
            Section {
                if finder.queryFragment.isEmpty {
                    ForEach(starterCities, id: \.self) { location in
                        locationRow(
                            title: location.name,
                            subtitle: location.subtitle,
                            isSelected: isLocationSelected(location)
                        ) {
                            selected = selected == location ? nil : location
                        }
                    }
                } else {
                    ForEach(finder.suggestions, id: \.self) { suggestion in
                        locationRow(
                            title: suggestion.title,
                            subtitle: suggestion.subtitle.isEmpty
                                ? nil : suggestion.subtitle,
                            isSelected: isSuggestionSelected(suggestion)
                        ) {
                            Task {
                                guard
                                    let city = await finder.selectCompletion(
                                        suggestion
                                    )
                                else { return }
                                selected = selected == city ? nil : city
                            }
                        }
                    }
                }
            }
        }
        .animation(.spring, value: selected)
        .listStyle(.plain)
        .background(Color(uiColor: .systemBackground).ignoresSafeArea())
        .safeAreaInset(edge: .top) {
            VStack(alignment: .leading, spacing: 12) {
                TextField(
                    "Search cities and addresses...",
                    text: $finder.queryFragment
                )
                .frame(maxHeight: 40)
                .padding(.horizontal)
                .glassEffect(.regular.interactive())
                .tint(accentColor.swiftUIColor)

                selectionIndicator
            }
            .padding(.horizontal)
        }
        .toolbar {
            bottomToolbar
            keyboardToolbar
        }
    }

    @ToolbarContentBuilder
    private var bottomToolbar: some ToolbarContent {
        if selected != nil {
            ToolbarItem(placement: .bottomBar) {
                currentLocationButton
            }
            .sharedBackgroundVisibility(.hidden)
        }
    }

    @ToolbarContentBuilder
    private var keyboardToolbar: some ToolbarContent {
        if selected != nil {
            ToolbarItem(placement: .keyboard) {
                currentLocationButton
            }
            .sharedBackgroundVisibility(.hidden)
        }
    }

    private var currentLocationButton: some View {
        AccentButtonView(label: "Use Current Location", systemImage: "location")
        {
            selected = nil
        }
    }

    private var selectionIndicator: some View {
        VStack(alignment: .leading, spacing: 6) {
            if selected != nil {
                PlannerChipView(
                    title: selected?.name
                        ?? locationManager.cityName,
                    iconName: "mappin.and.ellipse",
                    color: nil,
                    onTap: nil
                )
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "location")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)

                    VStack(alignment: .leading) {
                        Text("Current Location")
                            .font(.system(size: 14, weight: .medium))

                        Text(locationManager.cityName)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color(uiColor: .secondaryLabel))
                    }

                }
                .glassChip(color: nil, onTap: nil, height: 40)
            }
        }
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
