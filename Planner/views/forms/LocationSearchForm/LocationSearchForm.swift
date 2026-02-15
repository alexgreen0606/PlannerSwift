//
//  LocationSearch.swift
//  Planner
//
//  Created by Alex Green on 2/5/26.
//

import Combine
import MapKit
import SwiftData
import SwiftUI

enum LocationSearchMode {
    case planner
    case home
}

struct LocationSearchView: View {
    private let initialLocation: Location?
    private let initialLocationSource: LocationSource
    private let title: String
    private let mode: LocationSearchMode
    private let onSave: (LocationSource, Location?) -> Void
    
    init(
        initialLocation: Location?,
        initialLocationSource: LocationSource,
        title: String,
        mode: LocationSearchMode,
        onSave: @escaping (LocationSource, Location?) -> Void
    ) {
        self.initialLocation = initialLocation
        self.initialLocationSource = initialLocationSource
        self.title = title
        self.mode = mode
        self.onSave = onSave

        _selectedLocationSource = State(initialValue: initialLocationSource)
        _selectedLocation = State(initialValue: initialLocation)
    }

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var locationManager: DeviceLocationManager

    @Query private var plannerSettingsList: [PlannerSettings]
    @Query private var locations: [Location]

    @StateObject private var locationFinder = LocationFinder()
    @State private var selectedLocationSource: LocationSource
    @State private var selectedLocation: Location?
    @State private var existingLocations: [Location] = []

    private var topSuggestionId: String? {
        optionId(locationFinder.suggestions.first)
    }

    private var plannerSettings: PlannerSettings? {
        plannerSettingsList.first
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                if locationFinder.queryFragment.count < 2 {
                    fillerSuggestions
                } else {
                    searchResults(proxy: proxy)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                topLeftToolbar
                topRightToolbar
            }
            .safeAreaInset(edge: .top) {
                selectionHeader
            }
            .overlay {
                emptyOptionsLabel
            }
            .onAppear(perform: buildSuggestedLocations)
        }
    }

    // MARK: - Toolbars

    @ToolbarContentBuilder
    private var topLeftToolbar: some ToolbarContent {
        if mode == .planner {
            ToolbarItem(placement: .topBarLeading) {
                Button(
                    "Back",
                    systemImage: "xmark"
                ) {
                    dismiss()
                }
            }
        } else {
            ToolbarItem(placement: .topBarLeading) {
                Button(
                    "Back",
                    systemImage: "chevron.left"
                ) {
                    onSave(selectedLocationSource, selectedLocation)
                    dismiss()
                }
            }
        }
    }

    @ToolbarContentBuilder
    private var topRightToolbar: some ToolbarContent {
        if mode == .planner {
            ToolbarItem(placement: .confirmationAction) {
                Button("Confirm", systemImage: "checkmark") {
                    onSave(selectedLocationSource, selectedLocation)
                    dismiss()
                }
                .tint(accentColor.swiftUIColor)
            }
        }
    }

    // MARK: - Selection Header

    private var selectionHeader: some View {
        VStack(spacing: 16) {
            selectionIndicator
            inputField

            HStack {
                currentLocationButton
                Spacer()
                homeLocationButton
            }
        }
        .padding(.horizontal)
        .animateChange(from: selectedLocation)
        .animateChange(from: selectedLocationSource)
    }

    @ViewBuilder
    private var selectionIndicator: some View {
        if let selectedLocation, selectedLocationSource == .custom {
            PlannerChipView(
                title: selectedLocation.name,
                iconConfig: IconConfig(
                    name: "mappin.and.ellipse",
                    primaryColor: accentColor.swiftUIColor,
                    secondaryColor: Color.secondary
                ),
                color: nil,
                onTap: nil
            )
        } else if let home = plannerSettings?.homeLocation,
            selectedLocationSource == .home
        {
            homeLocationIndicator(home)
        } else {
            currentLocationIndicator
        }
    }

    private var currentLocationIndicator: some View {
        HStack(spacing: 6) {
            Image(systemName: "location")
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundStyle(Color.secondary)

            VStack(alignment: .leading) {
                Text("Current Location")
                    .font(.system(size: 14, weight: .medium))

                if let city = locationManager.cityName {
                    Text(city)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(
                            Color.secondary
                        )
                }
            }
        }
        .glassChip(color: nil, onTap: nil, height: 40)
    }

    @ViewBuilder
    private func homeLocationIndicator(_ home: Location) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "house")
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundStyle(Color.secondary)

            VStack(alignment: .leading) {
                Text("Home")
                    .font(.system(size: 14, weight: .medium))

                Text(home.name)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(
                        Color.secondary
                    )
            }

        }
        .glassChip(color: nil, onTap: nil, height: 40)
    }

    private var inputField: some View {
        TextField(
            "Search cities and addresses...",
            text: $locationFinder.queryFragment
        )
        .frame(maxHeight: 50)
        .padding(.horizontal)
        .glassEffect(.regular.interactive())
        .tint(accentColor.swiftUIColor)
    }

    @ViewBuilder
    private var currentLocationButton: some View {
        if selectedLocationSource != .current
            && !(selectedLocationSource == .home
                && plannerSettings?.homeLocation == nil)
        {
            AccentButtonView(
                label: "Current",
                systemImage: "location"
            ) {
                selectedLocationSource = .current
            }
        }
    }

    @ViewBuilder
    private var homeLocationButton: some View {
        if mode != .home, selectedLocationSource != .home,
            plannerSettings?.homeLocation != nil
        {
            AccentButtonView(
                label: "Home",
                systemImage: "house"
            ) {
                selectedLocationSource = .home
            }
        }
    }

    // MARK: - Suggestions List

    private var fillerSuggestions: some View {
        List {
            ForEach(existingLocations, id: \.self) { option in
                suggestionRow(option)
            }
        }
        .listStyle(.plain)
        .background(Color(uiColor: .systemBackground).ignoresSafeArea())
    }

    @ViewBuilder
    private func suggestionRow(_ suggestion: Location) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(suggestion.name)
                    .font(.headline)

                if let subtitle = suggestion.subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if isSuggestionSelected(suggestion) {
                Image(systemName: "checkmark")
            }
        }
        .discreetListItem()
        .contentShape(Rectangle())
        .onTapGesture {
            Task {
                selectedLocationSource = .custom
                selectedLocation = suggestion
            }
        }
    }

    // MARK: - Search Results List

    private func searchResults(proxy: ScrollViewProxy) -> some View {
        List {
            ForEach(locationFinder.suggestions, id: \.self) { option in
                optionRow(option)
            }
        }
        .listStyle(.plain)
        .background(Color(uiColor: .systemBackground).ignoresSafeArea())

        // Keep the list scrolled to the top when results change.
        .withScrollTrigger(
            proxy: proxy,
            trigger: locationFinder.suggestions,
            id: topSuggestionId
        )
    }

    @ViewBuilder
    private var emptyOptionsLabel: some View {
        if locationFinder.suggestions.isEmpty
            && locationFinder.queryFragment.count > 2
        {
            EmptyLabel(
                locationFinder.hasNetworkError
                    ? "No Internet Connection" : "No Matching Locations"
            )
        }
    }

    @ViewBuilder
    private func optionRow(_ option: MKLocalSearchCompletion) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(option.title)
                    .font(.headline)

                if !option.subtitle.isEmpty {
                    Text(option.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if isOptionSelected(option) {
                Image(systemName: "checkmark")
            }
        }
        .id(optionId(option))
        .discreetListItem()
        .contentShape(Rectangle())
        .onTapGesture {
            Task {
                guard let result = await locationFinder.selectCompletion(option)
                else {
                    return
                }

                selectedLocationSource = .custom

                // Re-use existing locations if they already exists in storage.
                let locationKey = coordinateKey(
                    lat: result.latitude,
                    long: result.longitude
                )

                guard
                    let existing = existingLocations.first(where: {
                        $0.key == locationKey
                    })
                else {
                    selectedLocation = Location(
                        name: result.name,
                        subtitle: result.subtitle,
                        latitude: result.latitude,
                        longitude: result.longitude,
                        timeZoneIdentifier: result.timeZoneIdentifier
                    )
                    return
                }

                selectedLocation = existing
            }
        }
    }

    // MARK: - Helper Function

    private func isOptionSelected(_ option: MKLocalSearchCompletion)
        -> Bool
    {
        guard selectedLocationSource == .custom, let selectedLocation else {
            return false
        }

        return selectedLocation.name == option.title
            && selectedLocation.subtitle == option.subtitle
    }

    private func isSuggestionSelected(_ suggestion: Location)
        -> Bool
    {
        selectedLocationSource == .custom && selectedLocation == suggestion
    }

    private func optionId(_ option: MKLocalSearchCompletion?) -> String? {
        guard let option else { return nil }

        return "\(option.title)-\(option.subtitle)"
    }

    private func buildSuggestedLocations() {
        var firstByKey: [String: Location] = [:]

        for location in locations {
            let key = location.key

            if firstByKey[key] == nil {
                firstByKey[key] = location
            }
        }

        let sortedLocations = firstByKey.values.sorted { lhs, rhs in
            if lhs.name != rhs.name {
                return lhs.name < rhs.name
            }

            return (lhs.subtitle ?? "") < (rhs.subtitle ?? "")
        }

        existingLocations = sortedLocations
    }

}
