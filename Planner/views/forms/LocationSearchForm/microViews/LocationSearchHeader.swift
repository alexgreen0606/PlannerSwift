//
//  LocationSearchHeader.swift
//  Planner
//
//  Created by Alex Green on 3/10/26.
//

import SwiftDate
import SwiftUI

// Clean

struct LocationSearchHeaderView: View {
    @ObservedObject var locationFinder: LocationFinder
    var isSearchFocused: FocusState<Bool>.Binding
    let sourcePlanner: Planner?
    let mode: LocationSearchMode
    let selectedLocation: Location?
    let homeLocation: Location?

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @EnvironmentObject private var deviceLocationManager: DeviceLocationManager

    private var tripLocation: Location? {
        sourcePlanner?.trip?.location
    }

    private var plannerLocation: Location? {
        sourcePlanner?.location
    }

    private var showCurrentIndicator: Bool {
        switch mode {
        case .home:
            return selectedLocation == nil
        case .trip:
            return selectedLocation == nil && homeLocation == nil
        case .planner:
            return selectedLocation == nil && homeLocation == nil
                && tripLocation == nil
        case .event:
            return selectedLocation == nil && homeLocation == nil
                && tripLocation == nil
                && plannerLocation == nil
        }
    }

    private var showHomeIndicator: Bool {
        guard homeLocation != nil else {
            return false
        }

        switch mode {
        case .home:
            return false
        case .trip:
            return selectedLocation == nil
        case .planner:
            return selectedLocation == nil && tripLocation == nil
        case .event:
            return selectedLocation == nil && plannerLocation == nil
                && tripLocation == nil
        }
    }

    private var showTripIndicator: Bool {
        guard tripLocation != nil else {
            return false
        }

        switch mode {
        case .home, .trip:
            return false
        case .planner:
            return selectedLocation == nil
        case .event:
            return selectedLocation == nil && plannerLocation == nil
        }
    }

    private var showPlannerIndicator: Bool {
        guard sourcePlanner != nil else {
            return false
        }

        switch mode {
        case .planner, .home, .trip:
            return false
        case .event:
            return selectedLocation == nil
        }

    }

    var body: some View {
        VStack {
            selectionIndicator
            inputField
        }
        .padding(.horizontal)
        .animateSynchronousAction(from: selectedLocation)
    }

    // MARK: - View Builders

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
            PlannerChipView(
                title: selectedLocation.name,
                iconConfig: IconConfig(
                    name: "mappin.and.ellipse",
                    primaryColor: accentColor.color,
                    secondaryColor: Color.secondary
                ),
                color: nil,
                contact: nil,
                onTap: nil
            )

        }
    }

    private var currentLocationIndicator: some View {
        LabelValueChipView(
            label: "Current Location",
            value: deviceLocationManager.deviceLocation?.name,
            iconConfig: IconConfig(name: "location")
        )
    }

    private func homeLocationIndicator(_ home: Location) -> some View {
        LabelValueChipView(
            label: "Home Location",
            value: home.name,
            iconConfig: IconConfig(name: "house")
        )
    }

    private func tripLocationIndicator(_ tripLocation: Location) -> some View {
        LabelValueChipView(
            label: "Trip Location",
            value: tripLocation.name,
            iconConfig: IconConfig(name: "suitcase")
        )
    }

    private func plannerLocationIndicator(_ plannerLocation: Location)
        -> some View
    {
        LabelValueChipView(
            label: "Planner Location",
            value: plannerLocation.name,
            iconConfig: IconConfig(
                name: sourcePlanner?.datestamp.calendarSymbolName ?? "note"
            )
        )
    }

    private var inputField: some View {
        TextField(
            "Search cities and addresses...",
            text: $locationFinder.locationSearchText
        )
        .padding()
        .glassEffect(.regular.interactive())
        .tint(accentColor.color)

        // Increase the focusable area of the field.
        .focused(isSearchFocused)
        .contentShape(Rectangle())
        .onTapGesture {
            isSearchFocused.wrappedValue = true
        }
    }

}
