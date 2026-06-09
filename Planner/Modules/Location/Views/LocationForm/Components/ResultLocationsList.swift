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
    let homeLocation: Location?
    let sourcePlanner: Planner?

    @EnvironmentObject private var locationSearchService: LocationSearchService

    private var topResultId: String? {
        locationSearchService.results.first?.nameId
    }

    // MARK: - Body

    var body: some View {
        ScrollViewReader { scrollProxy in
            List {
                ForEach(locationSearchService.results, id: \.self, content: row)
            }
            .listStyle(.plain)
            .background(Color.sheetBackground.ignoresSafeArea())

            // MARK: Scroll to the top of the list when the results change.

            .withScrollTrigger(
                scrollProxy: scrollProxy,
                trigger: locationSearchService.results,
                id: topResultId
            )
        }
    }

    // MARK: - View Builders

    @ViewBuilder
    private func row(for result: MKLocalSearchCompletion) -> some View {
        let isSelected = isResultSelected(result)

        LocationOptionView(
            title: result.title,
            subtitle: result.subtitle,
            isSelected: isSelected,
            nameId: result.nameId,
            homeLocation: homeLocation,
            sourcePlanner: sourcePlanner,
            selectOption: {
                selectResult(result, isSelected: isSelected)
            }
        )
    }

    // MARK: - Functions

    private func selectResult(
        _ result: MKLocalSearchCompletion,
        isSelected: Bool
    ) {
        if isSelected {
            withAnimation {
                selectedLocation = nil
            }
            return
        }

        Task {
            guard
                let location =
                await locationSearchService.locationInfo(
                    for: result
                )
            else {
                return
            }

            withAnimation {
                selectedLocation = location
            }
        }
    }

    private func isResultSelected(_ result: MKLocalSearchCompletion)
        -> Bool
    {
        guard let selectedId = selectedLocation?.nameId else {
            return false
        }

        return result.nameId == selectedId
    }
}
