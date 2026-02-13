//
//  LocationSearch.swift
//  Planner
//
//  Created by Alex Green on 2/5/26.
//

import Combine
import MapKit
import SwiftData
import SwiftUI

enum LocationSearchMode {
    case planner
    case home
}

struct LocationSearchView: View {
    let initialLocation: Location?
    let initialLocationSource: LocationSource
    let title: String
    let mode: LocationSearchMode
    let onSave: (LocationSource, Location?) -> Void

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @Query private var plannerSettingsList: [PlannerSettings]

    let locationManager = LocationManager.shared

    @StateObject private var locationFinder = LocationFinder()

    @State private var selectedLocationSource: LocationSource
    @State private var selectedLocation: Location?

    private var topSuggestionId: String? {
        optionId(locationFinder.suggestions.first)
    }

    private var plannerSettings: PlannerSettings? {
        plannerSettingsList.first
    }

    init(
        initialLocation: Location?,
        initialLocationSource: LocationSource,
        title: String,
        mode: LocationSearchMode,
        onSave: @escaping (LocationSource, Location?) -> Void
    ) {
        self.initialLocation = initialLocation
        self.initialLocationSource = initialLocationSource
        self.title = title
        self.mode = mode
        self.onSave = onSave

        _selectedLocationSource = State(initialValue: initialLocationSource)
        _selectedLocation = State(initialValue: initialLocation)
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                List {
                    ForEach(locationFinder.suggestions, id: \.self) { option in
                        optionRow(option)
                    }
                }
                .listStyle(.plain)
                .background(Color(uiColor: .systemBackground).ignoresSafeArea())

                // Keep the list scrolled to the top when results change.
                .withScrollTrigger(
                    proxy: proxy,
                    trigger: locationFinder.suggestions,
                    id: topSuggestionId
                )
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                topLeftToolbar
                topRightToolbar
            }
            .safeAreaInset(edge: .top) {
                selectionHeader
            }
            .overlay {
                emptyOptionsLabel
            }
        }
    }

    // MARK: - Toolbars

    @ToolbarContentBuilder
    private var topLeftToolbar: some ToolbarContent {
        if mode == .planner {
            ToolbarItem(placement: .topBarLeading) {
                Button(
                    "Back",
                    systemImage: "xmark"
                ) {
                    dismiss()
                }
            }
        } else {
            ToolbarItem(placement: .topBarLeading) {
                Button(
                    "Back",
                    systemImage: "chevron.left"
                ) {
                    onSave(selectedLocationSource, selectedLocation)
                    dismiss()
                }
            }
        }
    }

    @ToolbarContentBuilder
    private var topRightToolbar: some ToolbarContent {
        if mode == .planner {
            ToolbarItem(placement: .confirmationAction) {
                Button("Confirm", systemImage: "checkmark") {
                    onSave(selectedLocationSource, selectedLocation)
                    dismiss()
                }
                .tint(accentColor.swiftUIColor)
            }
        }
    }

    // MARK: - Selection Header

    private var selectionHeader: some View {
        VStack(spacing: 16) {
            selectionIndicator
            inputField

            HStack {
                currentLocationButton
                Spacer()
                homeLocationButton
            }
        }
        .padding(.horizontal)
        .animateChange(from: selectedLocation)
        .animateChange(from: selectedLocationSource)
    }

    @ViewBuilder
    private var selectionIndicator: some View {
        if let selectedLocation, selectedLocationSource == .custom {
            PlannerChipView(
                title: selectedLocation.name,
                iconConfig: IconConfig(
                    name: "mappin.and.ellipse",
                    primaryColor: accentColor.swiftUIColor,
                    secondaryColor: Color.secondary
                ),
                color: nil,
                onTap: nil
            )
        } else if let home = plannerSettings?.homeLocation,
            selectedLocationSource == .home
        {
            homeLocationIndicator(home)
        } else {
            currentLocationIndicator
        }
    }

    private var currentLocationIndicator: some View {
        HStack(spacing: 6) {
            Image(systemName: "location")
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundStyle(Color.secondary)

            VStack(alignment: .leading) {
                Text("Current Location")
                    .font(.system(size: 14, weight: .medium))

                if let city = locationManager.cityName {
                    Text(city)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(
                            Color.secondary
                        )
                }
            }
        }
        .glassChip(color: nil, onTap: nil, height: 40)
    }

    @ViewBuilder
    private func homeLocationIndicator(_ home: Location) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "house")
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundStyle(Color.secondary)

            VStack(alignment: .leading) {
                Text("Home")
                    .font(.system(size: 14, weight: .medium))

                Text(home.name)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(
                        Color.secondary
                    )
            }

        }
        .glassChip(color: nil, onTap: nil, height: 40)
    }

    private var inputField: some View {
        TextField(
            "Search cities and addresses...",
            text: $locationFinder.queryFragment
        )
        .frame(maxHeight: 50)
        .padding(.horizontal)
        .glassEffect(.regular.interactive())
        .tint(accentColor.swiftUIColor)
    }

    @ViewBuilder
    private var currentLocationButton: some View {
        if selectedLocationSource != .current
            && !(selectedLocationSource == .home
                && plannerSettings?.homeLocation == nil)
        {
            AccentButtonView(
                label: "Current",
                systemImage: "location"
            ) {
                selectedLocationSource = .current
            }
        }
    }

    @ViewBuilder
    private var homeLocationButton: some View {
        if mode != .home, selectedLocationSource != .home,
            plannerSettings?.homeLocation != nil
        {
            AccentButtonView(
                label: "Home",
                systemImage: "house"
            ) {
                selectedLocationSource = .home
            }
        }
    }

    // MARK: - Option Rows

    @ViewBuilder
    private var emptyOptionsLabel: some View {
        if locationFinder.suggestions.isEmpty
            && locationFinder.queryFragment.count > 2
        {
            EmptyLabel("No Matching Locations")
        }
    }

    @ViewBuilder
    private func optionRow(_ option: MKLocalSearchCompletion) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(option.title)
                    .font(.headline)

                if !option.subtitle.isEmpty {
                    Text(option.subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if isOptionSelected(option) {
                Image(systemName: "checkmark")
            }
        }
        .id(optionId(option))
        .discreetListItem()
        .contentShape(Rectangle())
        .onTapGesture {
            Task {
                guard
                    let city =
                        await locationFinder.selectCompletion(
                            option
                        )
                else { return }

                selectedLocationSource = .custom
                selectedLocation = selectedLocation == city ? nil : city
            }
        }
    }

    // MARK: - Helper Function

    private func isOptionSelected(_ option: MKLocalSearchCompletion)
        -> Bool
    {
        guard selectedLocationSource == .custom, let selectedLocation else {
            return false
        }

        return selectedLocation.name == option.title
            && selectedLocation.subtitle == option.subtitle
    }

    private func optionId(_ option: MKLocalSearchCompletion?) -> String? {
        guard let option else { return nil }

        return "\(option.title)-\(option.subtitle)"
    }
}
