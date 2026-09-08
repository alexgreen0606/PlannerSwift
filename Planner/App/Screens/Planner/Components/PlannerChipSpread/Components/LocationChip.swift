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
    let settings: Settings
    let namespace: Namespace.ID

    private let LOCATION_CHIP_ID = "LOCATION_CHIP_ID"

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var plannerService: PlannerService
    @EnvironmentObject private var plannerEngine: ListEngine<PlannerEvent>

    private var locationIconConfig: IconConfig {
        let config = planner.locationIconConfig(
            settings: settings,
            accentColor: accentColor
        )
        
        return IconConfig(
            name: config.name,
            primaryColor: plannerEngine.selectModeDisabledColor ?? config.primaryColor,
            secondaryColor: plannerEngine.selectModeDisabledColor ?? config.secondaryColor
        )
    }

    // MARK: - Body

    var body: some View {
        AdornedValue(
            locationLabel,
            iconConfig: locationIconConfig,
            color: plannerEngine.selectModeDisabledColor
        )
        .glassChip(
            color: plannerEngine.selectModeDisabledColor,
            height: PlannerLayout.CHIP_HEIGHT,
            onTap: plannerEngine.isSelectMode ? nil : {
                showLocationSheet = true
            }
        )
        .matchedTransitionSource(
            id: LOCATION_CHIP_ID,
            in: namespace
        )

        // MARK: Location Search Form

        .sheet(isPresented: $showLocationSheet) {
            LocationFormView(
                variant: .planner,
                subtitle: planner.datestamp.dateWithYear,
                initialLocation: planner.location,
                sourcePlanner: planner,
                settings: settings,
                saveSelection: { location in
                    modelContext.updatePlannerLocation(
                        for: planner,
                        to: location,
                        plannerService: plannerService
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
