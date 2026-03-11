//
//  LocationSearchHeader.swift
//  Planner
//
//  Created by Alex Green on 3/10/26.
//

import SwiftUI

// Clean

struct LocationSearchHeaderView: View {
    @ObservedObject var locationFinder: LocationFinder
    let mode: LocationSearchMode
    let selectedLocation: Location?
    let homeLocation: Location?

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @EnvironmentObject private var deviceLocationManager: DeviceLocationManager

    @FocusState private var isFocused: Bool

    private var showCurrentIndicator: Bool {
        switch mode {
        case .home:
            return selectedLocation == nil
        case .planner:
            return selectedLocation == nil && homeLocation == nil
        case .event:
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

        } else if let selectedLocation {
            PlannerChipView(
                title: selectedLocation.name,
                iconConfig: IconConfig(
                    name: "mappin.and.ellipse",
                    primaryColor: accentColor.color,
                    secondaryColor: Color.secondary
                ),
                color: nil,
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
            label: "Home",
            value: home.name,
            iconConfig: IconConfig(name: "house")
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
        .focused($isFocused)
        .contentShape(Rectangle())
        .onTapGesture {
            isFocused = true
        }
    }

}
