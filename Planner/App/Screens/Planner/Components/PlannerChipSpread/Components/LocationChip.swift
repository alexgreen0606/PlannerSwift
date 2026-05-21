//
//  LocationChip.swift
//  Planner
//
//  Created by Alex Green on 5/21/26.
//

import SwiftData
import SwiftUI

struct LocationChipView: View {
    @Binding var showLocationSheet: Bool
    let locationLabel: String
    let planner: Planner
    let settings: PlannerSettings
    let namespace: Namespace.ID

    private let LOCATION_CHIP_ID = "LOCATION_CHIP_ID"

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @Environment(\.modelContext) private var modelContext

    private var locationIconConfig: IconConfig {
        planner.locationIconConfig(
            settings: settings,
            accentColor: accentColor
        )
    }

    // MARK: - Body

    var body: some View {
        AdornedValueView(
            locationLabel,
            iconConfig: locationIconConfig
        )
        .glassChip(
            height: PlannerLayout.CHIP_HEIGHT,
            onTap: {
                showLocationSheet = true
            }
        )
        .matchedTransitionSource(
            id: LOCATION_CHIP_ID,
            in: namespace
        )

        // MARK: Location Search Form
        .sheet(isPresented: $showLocationSheet) {
            LocationSearchFormView(
                title: "Edit Planner Location",
                subtitle: planner.datestamp.dateWithYear,
                mode: .planner,
                settings: settings,
                initialLocation: planner.location,
                sourcePlanner: planner,
                saveSelection: { location in
                    modelContext.updatePlannerLocation(
                        for: planner,
                        to: location
                    )
                }
            )
            .navigationTransition(
                .zoom(
                    sourceID: LOCATION_CHIP_ID,
                    in: namespace
                )
            )
        }
    }
}
