//
//  SuggestedLocationsList.swift
//  Planner
//
//  Created by Alex Green on 3/10/26.
//

import SwiftUI

struct SuggestedLocationsListView: View {
    @Binding var selectedLocation: Location?
    let suggestedLocations: [Location]
    let homeLocation: Location?
    let sourcePlanner: Planner?

    // MARK: - Body

    var body: some View {
        List {
            ForEach(suggestedLocations, id: \.id, content: row)
        }
        .listStyle(.plain)
        .background(Color.sheetBackground.ignoresSafeArea())
    }

    // MARK: - View Builder

    private func row(for location: Location) -> some View {
        LocationOptionView(
            title: location.name,
            subtitle: location.subtitle,
            isSelected: selectedLocation === location,
            nameId: location.nameId,
            homeLocation: homeLocation,
            sourcePlanner: sourcePlanner,
            selectOption: {
                if selectedLocation === location {
                    withAnimation {
                        selectedLocation = nil
                    }
                    return
                }

                withAnimation {
                    selectedLocation = location
                }
            }
        )
    }
}
