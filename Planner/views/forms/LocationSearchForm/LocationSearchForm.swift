//
//  LocationSearchForm.swift
//  Planner
//
//  Created by Alex Green on 2/5/26.
//

import Combine
import MapKit
import SwiftData
import SwiftUI

// Clean

enum LocationSearchMode {
    case home
    case planner
    case event
}

struct LocationSearchFormView: View {
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
    private var recentLocations: [Location]

    @StateObject private var locationFinder = LocationFinder()
    @State private var suggestedLocations: [Location] = []
    @State private var selectedLocation: Location?

    private var showCurrentOption: Bool {
        switch mode {
        case .home:
            return selectedLocation != nil
        case .event, .planner:
            return false
        }
    }

    private var showHomeOption: Bool {
        switch mode {
        case .planner:
            return selectedLocation != nil
        case .home, .event:
            return false
        }
    }

    private var showNoOption: Bool {
        switch mode {
        case .event:
            return selectedLocation != nil
        case .home, .planner:
            return false
        }
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { scrollProxy in
                if locationFinder.locationSearchText.count < 2 {
                    SuggestedLocationsListView(
                        selectedLocation: $selectedLocation,
                        suggestedLocations: suggestedLocations,
                        sourcePlanner: sourcePlanner,
                        homeLocation: settings.homeLocation,
                        plannerLocation: plannerLocation,
                    )
                } else {
                    ResultLocationsListView(
                        selectedLocation: $selectedLocation,
                        locationFinder: locationFinder,
                        scrollProxy: scrollProxy
                    )
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                backButton
                saveButton
            }
            .safeAreaInset(edge: .top) {
                LocationSearchHeaderView(
                    locationFinder: locationFinder,
                    mode: mode,
                    selectedLocation: selectedLocation,
                    homeLocation: settings.homeLocation,
                )
            }
            .overlay {
                emptyOptionsLabel
            }
            .overlay {
                VStack {
                    Spacer()
                    currentLocationButton
                    homeLocationButton
                    noLocationButton
                }
            }
            .onAppear(perform: buildSuggestedLocations)

            // Re-build the suggestions once the device location loads.
            .onChange(of: deviceLocationManager.deviceLocation) { _, _ in
                buildSuggestedLocations()
            }
        }
    }

    // MARK: - Toolbars

    @ToolbarContentBuilder
    private var backButton: some ToolbarContent {
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
    private var saveButton: some ToolbarContent {
        if mode == .planner {
            ToolbarItem(placement: .confirmationAction) {
                Button("Confirm", systemImage: "checkmark", action: handleSave)
                    .tint(accentColor.color)
            }
        }
    }

    // MARK: - View Builders

    @ViewBuilder
    private var currentLocationButton: some View {
        if showCurrentOption {
            ActionButtonView(
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
            ActionButtonView(
                label: "Use Home Location",
                systemImage: "house"
            ) {
                selectedLocation = nil
            }
        }
    }

    @ViewBuilder
    private var noLocationButton: some View {
        if showNoOption {
            ActionButtonView(
                label: "No Location",
                systemImage: "xmark"
            ) {
                selectedLocation = nil
            }
        }
    }

    @ViewBuilder
    private var emptyOptionsLabel: some View {
        if locationFinder.results.isEmpty
            && locationFinder.locationSearchText.count > 2
        {
            EmptyLabelView(
                text: locationFinder.hasNetworkError
                    ? "No Internet Connection" : "No Matching Locations"
            )
        }
    }

    // MARK: - Functions

    private func buildSuggestedLocations() {
        var combinedLocations = recentLocations

        // Add the common locations to the top of the recents list.
        if let plannerLocation {
            combinedLocations.insert(plannerLocation, at: 0)
        }
        if let deviceLocation = deviceLocationManager.deviceLocation {
            combinedLocations.insert(deviceLocation, at: 0)
        }
        if let homeLocation = settings.homeLocation {
            combinedLocations.insert(homeLocation, at: 0)
        }

        // Build a unique list of locations.

        var suggestedLocations: [Location] = []
        var added: Set<String> = []

        for location in combinedLocations {
            let key = location.coordinateKey

            if !added.contains(key) {
                added.insert(key)
                suggestedLocations.append(location)
            }
        }

        self.suggestedLocations = suggestedLocations
    }

    private func handleSave() {

        // Mark the location as selected so it displays at the top of the recents list.
        selectedLocation?.selectedOn = .now

        saveSelection(selectedLocation)
        dismiss()
    }

}
