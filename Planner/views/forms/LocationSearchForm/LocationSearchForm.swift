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
    private let title: String
    private let mode: LocationSearchMode
    private let settings: PlannerSettings
    private let initialLocation: Location?
    private let sourcePlanner: Planner?
    private let plannerLocation: Location?
    private let saveSelection: (Location?) -> Void

    init(
        title: String,
        mode: LocationSearchMode,
        settings: PlannerSettings,
        initialLocation: Location?,
        sourcePlanner: Planner? = nil,
        saveSelection: @escaping (Location?) -> Void
    ) {
        self.title = title
        self.mode = mode
        self.settings = settings
        self.initialLocation = initialLocation
        self.sourcePlanner = sourcePlanner
        self.plannerLocation = sourcePlanner?.location
        self.saveSelection = saveSelection

        _selectedLocation = State(initialValue: initialLocation)
    }

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var deviceLocationManager: DeviceLocationManager

    @Query(sort: \Location.selectedOn, order: .reverse)
    private var locations: [Location]

    @StateObject private var locationFinder = LocationFinder()
    @State private var recentLocations: [Location] = []
    @State private var noTimeZoneKeys = Set<String>()

    // Will only be nil if the device location has not loaded yet.
    @State private var selectedLocation: Location?

    private var topSuggestionId: String? {
        optionId(locationFinder.suggestions.first)
    }

    private var deviceLocation: Location? {
        deviceLocationManager.location
    }

    private var homeLocation: Location? {
        settings.homeLocation
    }

    private var showCurrentOption: Bool {
        switch mode {
        case .home:
            return selectedLocation != nil
        case .planner, .event:
            return false
        }
    }

    private var showHomeOption: Bool {
        switch mode {
        case .planner:
            return homeLocation != nil && selectedLocation != nil
        case .home, .event:
            return false
        }
    }

    private var showHomeIndicator: Bool {
        switch mode {
        case .planner:
            return selectedLocation == nil
        case .home, .event:
            return false
        }
    }

    private var showCurrentIndicator: Bool {
        switch mode {
        case .home:
            return selectedLocation == nil
        case .planner, .event:
            return false
        }
    }

    private var isDirty: Bool {
        selectedLocation != initialLocation
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
                    .frame(maxWidth: .infinity)
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
                    systemImage: "chevron.left",
                    action: handleSave
                )
            }
        }
    }

    @ToolbarContentBuilder
    private var topRightToolbar: some ToolbarContent {
        if mode == .planner {
            ToolbarItem(placement: .confirmationAction) {
                Button("Confirm", systemImage: "checkmark", action: handleSave)
                    .tint(accentColor.swiftUIColor)
                    .disabled(!isDirty)
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
                Spacer()
            }
        }
        .padding(.horizontal)
        .animateSynchronousAction(from: selectedLocation)
    }

    @ViewBuilder
    private var selectionIndicator: some View {
        if showCurrentIndicator {

            currentLocationIndicator

        } else if showHomeIndicator, let homeLocation {

            homeLocationIndicator(homeLocation)

        } else if let selectedLocation {

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

        }
    }

    private var currentLocationIndicator: some View {
        LabelValueView(
            label: "Current Location",
            value: deviceLocation?.name,
            iconConfig: IconConfig(name: "location")
        )
    }

    private func homeLocationIndicator(_ home: Location) -> some View {
        LabelValueView(
            label: "Home",
            value: home.name,
            iconConfig: IconConfig(name: "house")
        )
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
                label: "Use Current Location",
                systemImage: "location"
            ) {
                selectedLocation = nil
            }
        }
    }

    @ViewBuilder
    private var homeLocationButton: some View {
        if showHomeOption {
            AccentButtonView(
                label: "Use Home Location",
                systemImage: "house"
            ) {
                selectedLocation = nil
            }
        }
    }

    // MARK: - Suggestions List

    @ViewBuilder
    private var fillerSuggestions: some View {
        List {
            ForEach(recentLocations, id: \.id) { option in
                suggestionRow(option)
            }
        }
        .listStyle(.plain)
        .background(Color(uiColor: .systemBackground).ignoresSafeArea())
    }

    private func suggestionRow(_ suggestion: Location) -> some View {
        HStack {
            VStack(alignment: .leading) {

                HStack {

                    if suggestion == homeLocation {
                        Image(systemName: "house")
                            .foregroundStyle(.secondary)
                            .imageScale(.small)
                    } else if suggestion == deviceLocation {
                        Image(systemName: "location")
                            .foregroundStyle(.secondary)
                            .imageScale(.small)
                    } else if suggestion == plannerLocation,
                        let plannerIcon = sourcePlanner?.datestamp
                            .calendarSymbolName
                    {
                        Image(systemName: plannerIcon)
                            .foregroundStyle(.secondary)
                            .imageScale(.small)
                    }

                    Text(suggestion.name)
                        .font(.headline)
                }

                if let subtitle = suggestion.subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if selectedLocation == suggestion {
                Image(systemName: "checkmark")
            }
        }
        .discreetListItem()
        .contentShape(Rectangle())
        .onTapGesture {
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

                selectedLocation = Location(
                    name: result.name,
                    subtitle: result.subtitle,
                    latitude: result.latitude,
                    longitude: result.longitude,
                    timeZoneIdentifier: timeZoneIdentifier
                )

            }
        }
    }

    // MARK: - Helper Function

    private func isOptionSelected(_ option: MKLocalSearchCompletion)
        -> Bool
    {
        guard let selectedLocation else {
            return false
        }

        return selectedLocation.name == option.title
            && selectedLocation.subtitle == option.subtitle
    }

    func optionHasNoTimeZone(_ option: MKLocalSearchCompletion) -> Bool {
        guard let optionId = optionId(option) else { return false }

        return noTimeZoneKeys.contains(optionId)
    }

    private func optionId(_ option: MKLocalSearchCompletion?) -> String? {
        guard let option else { return nil }

        return "\(option.title)-\(option.subtitle)"
    }

    // TODO: run this when device location loads in
    private func buildSuggestedLocations() {
        var sortedLocations = locations

        if let plannerLocation {
            sortedLocations.insert(plannerLocation, at: 0)
        }

        if let deviceLocation {
            sortedLocations.insert(deviceLocation, at: 0)
        }

        if let homeLocation {
            sortedLocations.insert(homeLocation, at: 0)
        }

        var recentLocations: [Location] = []
        var added: Set<String> = []

        for location in sortedLocations {
            let key = location.coordinateKey

            if !added.contains(key) {
                added.insert(key)
                recentLocations.append(location)
            }
        }

        self.recentLocations = recentLocations
    }

    private func handleSave() {

        // Mark the location as selected so it displays at the top of the recents list.
        selectedLocation?.selectedOn = .now

        saveSelection(selectedLocation)
        dismiss()
    }

}
