//
//  LocationSearch.swift
//  Planner
//
//  Created by Alex Green on 2/5/26.
//

import Combine
import MapKit
import SwiftUI

enum LocationSearchMode {
    case sheet
    case stack
}

struct LocationSearchView: View {
    let initialLocation: Location?
    let title: String
    let mode: LocationSearchMode
    let onSave: (Location?) -> Void

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @Environment(\.dismiss) private var dismiss

    let locationManager = LocationManager.shared

    @StateObject private var locationFinder = LocationFinder()
    @State private var selectedLocation: Location?

    private var topSuggestionId: String? {
        optionId(locationFinder.suggestions.first)
    }

    init(
        initialLocation: Location?,
        title: String,
        mode: LocationSearchMode,
        onSave: @escaping (Location?) -> Void
    ) {
        self.initialLocation = initialLocation
        self.title = title
        self.mode = mode
        self.onSave = onSave

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
                .prioritizeTopItemScroll(
                    proxy: proxy,
                    trigger: locationFinder.suggestions,
                    firstItemId: topSuggestionId
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
        if mode == .sheet {
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
                    onSave(selectedLocation)
                    dismiss()
                }
            }
        }
    }

    @ToolbarContentBuilder
    private var topRightToolbar: some ToolbarContent {
        if mode == .sheet {
            ToolbarItem(placement: .confirmationAction) {
                Button("Confirm", systemImage: "checkmark") {
                    onSave(selectedLocation)
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
            currentLocationButton
        }
        .padding(.horizontal)
        .animateChange(from: selectedLocation)
    }

    @ViewBuilder
    private var selectionIndicator: some View {
        if let selectedLocation {
            PlannerChipView(
                title: selectedLocation.name,
                iconConfig: IconConfig(
                    name: "mappin.and.ellipse",
                    primaryColor: accentColor.swiftUIColor,
                    secondaryColor: Color(uiColor: .secondaryLabel)
                ),
                color: nil,
                onTap: nil
            )
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
                .foregroundStyle(accentColor.swiftUIColor)

            VStack(alignment: .leading) {
                Text("Current Location")
                    .font(.system(size: 14, weight: .medium))

                if let city = locationManager.cityName {
                    Text(city)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(
                            Color(uiColor: .secondaryLabel)
                        )
                }
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
        if selectedLocation != nil {
            AccentButtonView(
                label: "Use Current Location",
                systemImage: "location"
            ) {
                selectedLocation = nil
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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
                selectedLocation = selectedLocation == city ? nil : city
            }
        }
    }

    // MARK: - Helper Function

    private func isOptionSelected(_ option: MKLocalSearchCompletion)
        -> Bool
    {
        guard let selectedLocation else {
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
