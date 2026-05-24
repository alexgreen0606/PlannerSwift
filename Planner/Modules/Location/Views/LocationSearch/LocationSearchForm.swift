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

enum LocationSearchMode {
    case home
    case planner
    case event
    case trip
}

struct LocationSearchFormView: View {
    private let title: String
    private let subtitle: String?
    private let mode: LocationSearchMode
    private let settings: PlannerSettings
    private let initialLocation: Location?
    private let sourcePlanner: Planner?
    private let plannerLocation: Location?
    private let saveSelection: (Location?) -> Void

    init(
        title: String,
        subtitle: String? = nil,
        mode: LocationSearchMode,
        settings: PlannerSettings,
        initialLocation: Location?,
        sourcePlanner: Planner? = nil,
        saveSelection: @escaping (Location?) -> Void
    ) {
        self.title = title
        self.subtitle = subtitle
        self.mode = mode
        self.settings = settings
        self.initialLocation = initialLocation
        self.sourcePlanner = sourcePlanner
        plannerLocation = sourcePlanner?.location
        self.saveSelection = saveSelection

        _selectedLocation = State(initialValue: initialLocation)
    }

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var locationService: LocationService

    @Query(sort: \Location.selectedOn, order: .reverse)
    private var recentLocations: [Location]

    @StateObject private var locationSearchService = LocationSearchService()
    @State private var suggestedLocations: [Location] = []
    @State private var selectedLocation: Location?

    @FocusState private var isSearchFocused: Bool

    private var showCurrentOption: Bool {
        switch mode {
        case .home:
            return selectedLocation != nil
        case .event, .planner, .trip:
            return false
        }
    }

    private var showHomeOption: Bool {
        switch mode {
        case .home:
            return false
        case .trip:
            return selectedLocation != nil
        case .planner:
            return selectedLocation != nil && sourcePlanner?.trip == nil
        case .event:
            return selectedLocation != nil && sourcePlanner == nil
        }
    }

    private var showTripOption: Bool {
        switch mode {
        case .planner:
            return selectedLocation != nil && sourcePlanner?.trip != nil
        case .home, .event, .trip:
            return false
        }
    }

    private var showPlannerOption: Bool {
        switch mode {
        case .event:
            return selectedLocation != nil && sourcePlanner != nil
        case .home, .planner, .trip:
            return false
        }
    }

    private var bottomBarPadding: CGFloat {
        if isSearchFocused {
            if mode == .home {
                return 16
            }
            return 8
        }

        if mode == .home {
            return 32
        }
        return 0
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { scrollProxy in
                if locationSearchService.locationSearchText.count < 2 {
                    SuggestedLocationsListView(
                        selectedLocation: $selectedLocation,
                        suggestedLocations: suggestedLocations,
                        sourcePlanner: sourcePlanner,
                        homeLocation: settings.homeLocation,
                        plannerLocation: plannerLocation
                    )
                } else {
                    ResultLocationsListView(
                        selectedLocation: $selectedLocation,
                        locationSearchService: locationSearchService,
                        scrollProxy: scrollProxy
                    )
                }
            }
            .navigationTitle(title)
            .navigationSubtitle(subtitle ?? "")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                backButton
                saveButton
            }
            .safeAreaInset(edge: .top) {
                LocationSearchHeaderView(
                    locationSearchService: locationSearchService,
                    isSearchFocused: $isSearchFocused,
                    sourcePlanner: sourcePlanner,
                    mode: mode,
                    selectedLocation: selectedLocation,
                    homeLocation: settings.homeLocation
                )
            }
            .safeAreaInset(edge: .bottom) {
                bottomButton
            }
            .overlay {
                emptyOptionsLabel
            }
            .animateSynchronousAction(from: selectedLocation)
            // Build the suggestions once the device location loads.
            .task(id: locationService.deviceLocation) {
                buildSuggestedLocations()
            }
        }
    }

    // MARK: - Toolbars

    @ToolbarContentBuilder
    private var backButton: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Group {
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
            .tint(Color.label)
            .foregroundStyle(Color.label)
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

    private var bottomButton: some View {
        ZStack {
            currentLocationButton
            homeLocationButton
            plannerLocationButton
            tripLocationButton
        }
        .padding(.horizontal)
        .padding(.top)
        .padding(.bottom, bottomBarPadding)
    }

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
    private var tripLocationButton: some View {
        if showTripOption {
            ActionButtonView(
                label: "Use Trip Location",
                systemImage: "suitcase"
            ) {
                selectedLocation = nil
            }
        }
    }

    @ViewBuilder
    private var plannerLocationButton: some View {
        if showPlannerOption {
            ActionButtonView(
                label: "Use Planner Location",
                systemImage: sourcePlanner?.datestamp.calendarSymbolName
                    ?? "note"
            ) {
                selectedLocation = nil
            }
        }
    }

    @ViewBuilder
    private var emptyOptionsLabel: some View {
        if locationSearchService.results.isEmpty
            && locationSearchService.locationSearchText.count > 2
        {
            EmptyLabel(
                locationSearchService.hasNetworkError
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
        if let tripLocation = sourcePlanner?.trip?.location {
            combinedLocations.insert(tripLocation, at: 0)
        }
        if let deviceLocation = locationService.deviceLocation {
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
