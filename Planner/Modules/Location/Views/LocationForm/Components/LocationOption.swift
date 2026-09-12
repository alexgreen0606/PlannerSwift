//
//  LocationOption.swift
//  Planner
//
//  Created by Alex Green on 5/30/26.
//

import MapKit
import SwiftUI

struct LocationOptionView: View {
    let title: String
    let subtitle: String?
    let isSelected: Bool
    let nameId: String
    let homeLocation: Location?
    let sourcePlanner: Planner?
    let selectOption: () -> Void

    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var locationSearchService: LocationSearchService

    private var isDeviceLocation: Bool {
        title == locationService.validDeviceLocationName
    }

    private var isHomeLocation: Bool {
        nameId == homeLocation?.nameId
    }

    private var isTripLocation: Bool {
        nameId == sourcePlanner?.trip?.location?.nameId
    }

    private var isPlannerLocation: Bool {
        nameId == sourcePlanner?.location?.nameId
    }

    private var hasNoTimeZone: Bool {
        locationSearchService.noTimeZoneIds.contains(nameId)
    }

    private var opacity: CGFloat {
        hasNoTimeZone ? 0.3 : 1
    }

    // MARK: - Body

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Group {
                    Text(title)
                        .font(.headline)

                    if let subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 2)
                    }

                    HStack(alignment: .bottom, spacing: 0) {
                        if isDeviceLocation {
                            Image(systemName: "location")
                        }

                        if isHomeLocation {
                            Image(systemName: "house")
                        }

                        if isTripLocation {
                            Image(systemName: "suitcase")
                        }

                        if isPlannerLocation,
                            let plannerIcon = sourcePlanner?.datestamp
                                .calendarSymbolName
                        {
                            Image(systemName: plannerIcon)
                        }
                    }
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                }
                .opacity(opacity)

                if hasNoTimeZone {
                    Text("This location has no time zone and cannot be used.")
                        .font(
                            .system(size: 12, weight: .medium, design: .rounded)
                        )
                        .foregroundColor(.red)
                        .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if isSelected {
                Image(systemName: "checkmark")
            }
        }
        .id(nameId)
        .discreetListItem()
        .contentShape(Rectangle())
        .onTapGesture(perform: selectOption)
    }
}
