//
//  LocationForm.swift
//  Planner
//
//  Created by Alex Green on 2/5/26.
//

import Combine
import MapKit
import SwiftData
import SwiftUI

struct LocationFormView: View {
    private let variant: LocationFormVariant
    private let subtitle: String?
    private let settings: Settings
    private let sourcePlanner: Planner?
    private let saveSelection: (Location?) -> Void

    init(
        variant: LocationFormVariant,
        subtitle: String? = nil,
        initialLocation: Location?,
        sourcePlanner: Planner? = nil,
        settings: Settings,
        saveSelection: @escaping (Location?) -> Void
    ) {
        self.variant = variant
        self.subtitle = subtitle
        self.sourcePlanner = sourcePlanner
        self.settings = settings
        self.saveSelection = saveSelection

        _selectedLocation = State(initialValue: initialLocation)
    }

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var locationSearchService: LocationSearchService

    @Query(sort: \Location.selectedOn, order: .reverse)
    private var recentLocations: [Location]

    @State private var selectedLocation: Location?

    @State private var suggestedLocations: [Location] = []

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                if locationSearchService.text.count < 2 {
                    SuggestedLocationsListView(
                        selectedLocation: $selectedLocation,
                        variant: variant,
                        suggestedLocations: suggestedLocations,
                        homeLocation: settings.homeLocation,
                        sourcePlanner: sourcePlanner
                    )
                } else {
                    ResultLocationsListView(
                        selectedLocation: $selectedLocation,
                        variant: variant,
                        homeLocation: settings.homeLocation,
                        sourcePlanner: sourcePlanner
                    )
                }
            }
            .safeAreaInset(edge: .top) {
                LocationFormHeaderView(
                    selectedLocation: $selectedLocation,
                    formVariant: variant,
                    homeLocation: settings.homeLocation,
                    sourcePlanner: sourcePlanner
                )
            }
            .overlay {
                emptyOptionsLabel
            }
            .toolbar {
                backButton
                saveButton
            }
            .navigationTitle(variant.title)
            .navigationSubtitle(subtitle ?? "")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .interactiveDismissDisabled(true)

            // MARK: Build the suggestions on mount and if the device location changes.

            .task(id: locationService.validDeviceLocationName) {
                buildSuggestedLocations()
            }
        }
    }

    // MARK: - Toolbars

    @ToolbarContentBuilder
    private var backButton: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if variant == .planner {
                CancelButtonView(cancel: {
                    dismiss()
                })
            } else {
                BackButtonView(dismiss: saveLocation)
            }
        }
    }

    @ToolbarContentBuilder
    private var saveButton: some ToolbarContent {
        if variant == .planner {
            FormSaveButtonView(save: saveLocation)
        }
    }

    // MARK: - View Builders

    @ViewBuilder
    private var emptyOptionsLabel: some View {
        if locationSearchService.results.isEmpty
            && locationSearchService.text.count > 2
        {
            EmptyLabel(
                locationSearchService.hasNetworkError
                    ? "No internet connection" : "No matching locations"
            )
        }
    }

    // MARK: - Functions

    private func saveLocation() {
        // Mark the location as selected so it displays at the top of the recents list.
        selectedLocation?.selectedOn = .now

        saveSelection(selectedLocation)

        dismiss()
    }

    private func buildSuggestedLocations() {
        var combinedLocations = recentLocations

        if variant == .home
            && settings.homeLocation == nil
            && !locationService.validDeviceLocationName.isEmpty
        {
            buildInitialCurrentLocationMatches()
            return
        }

        // Add common locations to the top of the recents list.

        if let plannerLocation = sourcePlanner?.location {
            combinedLocations.insert(plannerLocation, at: 0)
        }
        if let tripLocation = sourcePlanner?.trip?.location {
            combinedLocations.insert(tripLocation, at: 0)
        }
        if let homeLocation = settings.homeLocation {
            combinedLocations.insert(homeLocation, at: 0)
        }

        // Build a unique list of locations.

        var suggestedLocations: [Location] = []
        var addedNameIds: Set<String> = []

        for location in combinedLocations {
            let nameId = location.nameId

            if !addedNameIds.contains(nameId) {
                suggestedLocations.append(location)
                addedNameIds.insert(nameId)
            }
        }

        self.suggestedLocations = suggestedLocations
    }

    private func buildInitialCurrentLocationMatches() {
        locationSearchService.text = locationService.validDeviceLocationName
    }
}
