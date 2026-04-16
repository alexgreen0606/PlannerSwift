//
//  SuggestedLocationsList.swift
//  Planner
//
//  Created by Alex Green on 3/10/26.
//

import SwiftUI

// Clean

struct SuggestedLocationsListView: View {
    @Binding var selectedLocation: Location?
    let suggestedLocations: [Location]
    let sourcePlanner: Planner?
    let homeLocation: Location?
    let plannerLocation: Location?

    @EnvironmentObject private var deviceLocationManager: DeviceLocationManager

    var body: some View {
        List {
            ForEach(suggestedLocations, id: \.id, content: row)
        }
        .listStyle(.plain)
        .background(Color(uiColor: .systemBackground).ignoresSafeArea())
    }

    private func row(for location: Location) -> some View {
        HStack {
            VStack(alignment: .leading) {

                HStack {

                    Group {
                        if location == homeLocation {
                            Image(systemName: "house")
                        } else if location == sourcePlanner?.trip?.location {
                            Image(systemName: "suitcase")
                        } else if location
                            == deviceLocationManager.deviceLocation
                        {
                            Image(systemName: "location")
                        } else if location == plannerLocation,
                            let plannerIcon = sourcePlanner?.datestamp
                                .calendarSymbolName
                        {
                            Image(systemName: plannerIcon)
                        }
                    }
                    .foregroundStyle(.secondary)
                    .imageScale(.small)

                    Text(location.name)
                        .font(.headline)
                }

                if let subtitle = location.subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if selectedLocation == location {
                Image(systemName: "checkmark")
            }
        }
        .discreetListItem()
        .contentShape(Rectangle())
        .onTapGesture {
            if selectedLocation === location {
                selectedLocation = nil
                return
            }
            
            selectedLocation = location
        }
    }
}
