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
    case home
    case planner
    case event
}

struct LocationSearchView: View {
    private let initialLocation: Location?
    private let initialLocationSource: LocationSource
    private let title: String
    private let sourcePlanner: Planner?
    private let mode: LocationSearchMode
    private let onSave: (LocationSource, Location?) -> Void

    init(
        initialLocation: Location?,
        initialLocationSource: LocationSource,
        title: String,
        sourcePlanner: Planner? = nil,
        mode: LocationSearchMode,
        onSave: @escaping (LocationSource, Location?) -> Void
    ) {
        self.initialLocation = initialLocation
        self.initialLocationSource = initialLocationSource
        self.title = title
        self.sourcePlanner = sourcePlanner
        self.mode = mode
        self.onSave = onSave

        _selectedLocationSource = State(initialValue: initialLocationSource)
        _selectedLocation = State(initialValue: initialLocation)
    }

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var locationManager: DeviceLocationManager

    @Query private var plannerSettingsList: [PlannerSettings]
    @Query private var locations: [Location]

    @StateObject private var locationFinder = LocationFinder()
    @State private var selectedLocationSource: LocationSource
    @State private var selectedLocation: Location?
    @State private var existingLocations: [Location] = []
    @State private var noTimeZoneKeys = Set<String>()

    private var topSuggestionId: String? {
        optionId(locationFinder.suggestions.first)
    }

    private var settings: PlannerSettings? {
        plannerSettingsList.first
    }

    private var showCurrentOption: Bool {
        selectedLocationSource != .current
            && !(selectedLocationSource == .home
                && settings?.homeLocation == nil)
            && !(selectedLocationSource == .planner
                && settings?.homeLocation == nil)
    }

    private var showHomeOption: Bool {
        mode != .home
            && selectedLocationSource != .home
            && settings?.homeLocation != nil
    }

    private var showPlannerOption: Bool {
        mode == .event
            && selectedLocationSource != .planner
            && sourcePlanner?.location != nil
            && sourcePlanner?.datestamp.calendarSymbolName != nil
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { scrollProxy in
                if locationFinder.queryFragment.count < 2 {
                    fillerSuggestions
                } else {
                    searchResults(scrollProxy: scrollProxy)
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
        ToolbarItem(placement: .topBarLeading) {
            if mode == .planner {
                Button(
                    "Close",
                    systemImage: "xmark"
                ) {
                    dismiss()
                }
            } else {
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
                homeLocationButton
                plannerLocationButton
            }
        }
        .padding(.horizontal)
        .animateSynchronousAction(from: selectedLocation)
        .animateSynchronousAction(from: selectedLocationSource)
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
        } else if let home = settings?.homeLocation,
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

                if locationManager.cityName != "Current Location" {
                    Text(locationManager.cityName)
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
        if showCurrentOption {
            AccentButtonView(
                label: "Current",
                systemImage: "location"
            ) {
                selectedLocationSource = .current
            }

            Spacer()
        }
    }

    @ViewBuilder
    private var homeLocationButton: some View {
        if showHomeOption {
            AccentButtonView(
                label: "Home",
                systemImage: "house"
            ) {
                selectedLocationSource = .home
            }
        }
    }

    @ViewBuilder
    private var plannerLocationButton: some View {
        if let sourcePlannerIcon = sourcePlanner?.datestamp.calendarSymbolName {
            if showPlannerOption {

                if showHomeOption {
                    Spacer()
                }

                AccentButtonView(
                    label: "Planner",
                    systemImage: sourcePlannerIcon
                ) {
                    selectedLocationSource = .planner
                }
            }
        }
    }

    // MARK: - Suggestions List

    @ViewBuilder
    private var fillerSuggestions: some View {
        List {
            ForEach(existingLocations, id: \.id) { option in
                suggestionRow(option)
            }
        }
        .listStyle(.plain)
        .background(Color(uiColor: .systemBackground).ignoresSafeArea())
    }

    @ViewBuilder
    private func suggestionRow(_ suggestion: Location) -> some View {
        let isSelected = isSuggestionSelected(suggestion)

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

            if isSelected {
                Image(systemName: "checkmark")
            }
        }
        .discreetListItem()
        .contentShape(Rectangle())
        .onTapGesture {
            selectedLocationSource = .custom
            selectedLocation = suggestion
        }
    }

    // MARK: - Search Results List

    private func searchResults(scrollProxy: ScrollViewProxy) -> some View {
        List {
            ForEach(locationFinder.suggestions, id: \.self) { option in
                optionRow(option)
            }
        }
        .listStyle(.plain)
        .background(Color(uiColor: .systemBackground).ignoresSafeArea())

        // Keep the list scrolled to the top when results change.
        .withScrollTrigger(
            scrollProxy: scrollProxy,
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
        let hasNoTimeZone = optionHasNoTimeZone(option)
        let isSelected = isOptionSelected(option)

        HStack {
            VStack(alignment: .leading) {
                Text(option.title)
                    .font(.headline)
                    .opacity(hasNoTimeZone ? 0.3 : 1)

                if !option.subtitle.isEmpty {
                    Text(option.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .opacity(hasNoTimeZone ? 0.3 : 1)
                }

                if hasNoTimeZone {
                    Text("This location has no time zone and cannot be used.")
                        .font(
                            .system(size: 12, weight: .medium, design: .rounded)
                        )
                        .foregroundColor(.red)
                        .padding(.top, 2)
                }
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark")
            }
        }
        .animateSynchronousAction(from: hasNoTimeZone)
        .id(optionId(option))
        .discreetListItem()
        .contentShape(Rectangle())
        .onTapGesture {
            Task {
                guard let optionId = optionId(option) else { return }

                guard !noTimeZoneKeys.contains(optionId) else { return }

                guard let result = await locationFinder.selectCompletion(option)
                else {
                    return
                }

                // Skip locations that do not have a TimeZone.
                guard let timeZoneIdentifier = result.timeZoneIdentifier else {
                    noTimeZoneKeys.insert(optionId)
                    return
                }

                // Re-use existing locations if they already exists in storage.
                let coordinateKey = CLLocationCoordinate2D(
                    latitude: result.latitude,
                    longitude: result.longitude
                ).key

                selectedLocationSource = .custom

                guard
                    let existing = existingLocations.first(where: {
                        $0.coordinateKey == coordinateKey
                    })
                else {

                    selectedLocation = Location(
                        name: result.name,
                        subtitle: result.subtitle,
                        latitude: result.latitude,
                        longitude: result.longitude,
                        timeZoneIdentifier: timeZoneIdentifier
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

    func optionHasNoTimeZone(_ option: MKLocalSearchCompletion) -> Bool {
        guard let optionId = optionId(option) else { return false }

        return noTimeZoneKeys.contains(optionId)
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
            let key = location.coordinateKey

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
