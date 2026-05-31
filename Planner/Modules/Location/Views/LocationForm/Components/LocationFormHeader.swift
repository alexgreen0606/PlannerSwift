//
//  LocationFormHeader.swift
//  Planner
//
//  Created by Alex Green on 3/10/26.
//

import SwiftUI

struct LocationFormHeaderView: View {
    @Binding var selectedLocation: Location?
    let formVariant: LocationFormVariant
    let homeLocation: Location?
    let sourcePlanner: Planner?

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var locationSearchService: LocationSearchService
    
    @FocusState private var isSearchFocused

    private var tripLocation: Location? {
        sourcePlanner?.trip?.location
    }

    private var plannerLocation: Location? {
        sourcePlanner?.location
    }

    private var deviceLocationLabel: LocalizedStringKey? {
        guard let deviceLocation = locationService.deviceLocation else {
            return nil
        }

        return LocalizedStringKey(deviceLocation.name)
    }

    // MARK: Indicators

    private var showCurrentIndicator: Bool {
        switch formVariant {
        case .home:
            return selectedLocation == nil
        case .trip:
            return selectedLocation == nil
                && homeLocation == nil
        case .planner:
            return selectedLocation == nil
                && homeLocation == nil
                && tripLocation == nil
        case .event:
            return selectedLocation == nil
                && homeLocation == nil
                && tripLocation == nil
                && plannerLocation == nil
        }
    }

    private var showHomeIndicator: Bool {
        guard homeLocation != nil else {
            return false
        }

        switch formVariant {
        case .home:
            return false
        case .trip:
            return selectedLocation == nil
        case .planner:
            return selectedLocation == nil
                && tripLocation == nil
        case .event:
            return selectedLocation == nil
                && tripLocation == nil
                && plannerLocation == nil
        }
    }

    private var showTripIndicator: Bool {
        guard tripLocation != nil else {
            return false
        }

        switch formVariant {
        case .home, .trip:
            return false
        case .planner:
            return selectedLocation == nil
        case .event:
            return selectedLocation == nil
                && plannerLocation == nil
        }
    }

    private var showPlannerIndicator: Bool {
        guard sourcePlanner != nil else {
            return false
        }

        switch formVariant {
        case .planner, .home, .trip:
            return false
        case .event:
            return selectedLocation == nil
        }
    }

    // MARK: Options

    private var showCurrentOption: Bool {
        switch formVariant {
        case .home:
            return selectedLocation != nil
        case .event, .planner, .trip:
            return false
        }
    }

    private var showHomeOption: Bool {
        switch formVariant {
        case .home:
            return false
        case .trip:
            return selectedLocation != nil
        case .planner:
            return selectedLocation != nil
                && tripLocation == nil
        case .event:
            return false
        }
    }

    private var showTripOption: Bool {
        switch formVariant {
        case .home, .trip:
            return false
        case .planner:
            return selectedLocation != nil
                && tripLocation != nil
        case .event:
            return false
        }
    }

    private var showPlannerOption: Bool {
        switch formVariant {
        case .home, .trip, .planner:
            return false
        case .event:
            return selectedLocation != nil
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading) {
            selectionIndicator
            textfield
            clearSelectionButton
        }
        .padding(.horizontal)
    }

    // MARK: - View Builders

    // MARK: Indicators

    @ViewBuilder
    private var selectionIndicator: some View {
        if showCurrentIndicator {
            currentLocationIndicator

        } else if showHomeIndicator, let homeLocation {
            homeLocationIndicator(homeLocation)

        } else if showTripIndicator, let tripLocation {
            tripLocationIndicator(tripLocation)

        } else if showPlannerIndicator, let plannerLocation {
            plannerLocationIndicator(plannerLocation)

        } else if let selectedLocation {
            AdornedValue(
                selectedLocation.name,
                iconConfig: IconConfig(
                    name: "mappin.and.ellipse",
                    primaryColor: accentColor.color
                )
            )
            .glassChip(height: 40)
        }
    }

    private var currentLocationIndicator: some View {
        LabelValueView(
            title: "Current Location",
            subtitle: deviceLocationLabel,
            iconConfig: IconConfig(name: "location")
        )
        .animateLazyAction(from: deviceLocationLabel)
        .glassChip(height: 46)
    }

    private func homeLocationIndicator(_ home: Location) -> some View {
        LabelValueView(
            title: "Home Location",
            subtitle: LocalizedStringKey(home.name),
            iconConfig: IconConfig(name: "house")
        )
        .glassChip(height: 46)
    }

    private func tripLocationIndicator(_ tripLocation: Location) -> some View {
        LabelValueView(
            title: "Trip Location",
            subtitle: LocalizedStringKey(tripLocation.name),
            iconConfig: IconConfig(name: "suitcase")
        )
        .glassChip(height: 46)
    }

    private func plannerLocationIndicator(_ plannerLocation: Location)
        -> some View
    {
        LabelValueView(
            title: "Planner Location",
            subtitle: LocalizedStringKey(plannerLocation.name),
            iconConfig: IconConfig(
                name: sourcePlanner?.datestamp.calendarSymbolName ?? "note"
            )
        )
        .glassChip(height: 46)
    }

    // MARK: Textfield

    private var textfield: some View {
        TextField(
            "Search cities and addresses...",
            text: $locationSearchService.text
        )
        .focused($isSearchFocused)
        .tint(accentColor.color)
        .padding()
        .glassEffect(.regular.interactive())

        // Increase the focusable area of the field.
        .contentShape(Rectangle())
        .onTapGesture {
            isSearchFocused = true
        }
    }

    // MARK: Options

    private var clearSelectionButton: some View {
        Group {
            currentLocationButton
            homeLocationButton
            plannerLocationButton
            tripLocationButton
        }
        .padding(.top, 8)
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
}
