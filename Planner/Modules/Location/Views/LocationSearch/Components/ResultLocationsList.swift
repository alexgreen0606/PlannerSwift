//
//  ResultLocationsList.swift
//  Planner
//
//  Created by Alex Green on 3/10/26.
//

import MapKit
import SwiftUI

struct ResultLocationsListView: View {
    @Binding var selectedLocation: Location?
    @ObservedObject var locationSearchService: LocationSearchService
    let scrollProxy: ScrollViewProxy

    @State private var noTimeZoneKeys = Set<String>()

    private var upperResultId: String? {
        locationSearchService.results.first?.id
    }

    var body: some View {
        List {
            ForEach(locationSearchService.results, id: \.self, content: row)
        }
        .listStyle(.plain)
        .background(Color(uiColor: .systemBackground).ignoresSafeArea())
        // Scroll to the top of the list when the results change.
        .withScrollTrigger(
            scrollProxy: scrollProxy,
            trigger: locationSearchService.results,
            id: upperResultId
        )
    }

    // MARK: - View Builders

    @ViewBuilder
    private func row(for result: MKLocalSearchCompletion) -> some View {
        let hasNoTimeZone = noTimeZoneKeys.contains(result.id)
        let isSelected = isResultSelected(result)

        HStack {
            VStack(alignment: .leading) {
                Text(result.title)
                    .font(.headline)
                    .opacity(hasNoTimeZone ? 0.3 : 1)

                if !result.subtitle.isEmpty {
                    Text(result.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .opacity(hasNoTimeZone ? 0.3 : 1)
                }

                if hasNoTimeZone {
                    Text("This location has no time zone and cannot be used.")
                        .font(
                            .system(size: 12, weight: .medium, design: .rounded)
                        )
                        .foregroundColor(.red)
                        .padding(.top, 2)
                }
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark")
            }
        }
        .id(result.id)
        .animateSynchronousAction(from: hasNoTimeZone)
        .discreetListItem()
        .contentShape(Rectangle())
        .onTapGesture {
            if isSelected {
                selectedLocation = nil
                return
            }

            Task {
                guard !noTimeZoneKeys.contains(result.id),
                      let locationInfo =
                      await locationSearchService.getOptionLocationInfo(
                          result
                      )
                else {
                    return
                }

                // Skip locations that do not have a TimeZone.
                guard let timeZoneIdentifier = locationInfo.timeZoneIdentifier
                else {
                    noTimeZoneKeys.insert(result.id)
                    return
                }

                selectedLocation = Location(
                    name: locationInfo.name,
                    subtitle: locationInfo.subtitle,
                    latitude: locationInfo.latitude,
                    longitude: locationInfo.longitude,
                    timeZoneIdentifier: timeZoneIdentifier
                )
            }
        }
    }

    // MARK: - Functions

    private func isResultSelected(_ result: MKLocalSearchCompletion)
        -> Bool
    {
        selectedLocation?.name == result.title
            && selectedLocation?.subtitle == result.subtitle
    }
}
