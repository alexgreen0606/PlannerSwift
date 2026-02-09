//
//  LocationSearch.swift
//  Planner
//
//  Created by Alex Green on 2/5/26.
//

import Combine
import MapKit
import SwiftUI

struct LocationSearchView: View {
    let initialLocation: Location?
    @Binding var selected: Location?

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @StateObject private var finder = LocationFinder()

    let locationManager = LocationManager.shared

    private var topSuggestionId: String? {
        suggestionId(finder.suggestions.first)
    }

    var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(finder.suggestions, id: \.self) { suggestion in
                    locationRow(
                        title: suggestion.title,
                        subtitle: suggestion.subtitle.isEmpty
                            ? nil : suggestion.subtitle,
                        isSelected: isSuggestionSelected(suggestion)
                    ) {
                        Task {
                            guard
                                let city =
                                    await finder.selectCompletion(
                                        suggestion
                                    )
                            else { return }
                            selected = selected == city ? nil : city
                        }
                    }
                    .id(suggestionId(suggestion))
                }
            }
            .listStyle(.plain)
            .overlay {
                if finder.suggestions.isEmpty && finder.queryFragment.count > 2
                {
                    EmptyLabel("No Matching Locations")
                }
            }
            .animation(.spring, value: selected)
            .background(Color(uiColor: .systemBackground).ignoresSafeArea())
            .safeAreaInset(edge: .top) {
                VStack(alignment: .leading, spacing: 12) {
                    selectionIndicator

                    TextField(
                        "Search cities and addresses...",
                        text: $finder.queryFragment
                    )
                    .frame(maxHeight: 50)
                    .padding(.horizontal)
                    .glassEffect(.regular.interactive())
                    .tint(accentColor.swiftUIColor)
                    .toolbar {
                        bottomToolbar
                        keyboardToolbar
                    }
                }
                .padding(.horizontal)
            }

            // Keep the list scrolled to the top when results change.
            .prioritizeTopItemScroll(
                proxy: proxy,
                trigger: finder.suggestions,
                firstItemId: topSuggestionId
            )
        }
    }

    @ToolbarContentBuilder
    private var bottomToolbar: some ToolbarContent {
        if selected != nil {
            ToolbarItem(placement: .bottomBar) {
                currentLocationButton
            }
            .sharedBackgroundVisibility(.hidden)
        }
    }

    @ToolbarContentBuilder
    private var keyboardToolbar: some ToolbarContent {
        if selected != nil {
            ToolbarItem(placement: .keyboard) {
                currentLocationButton
            }
            .sharedBackgroundVisibility(.hidden)
        }
    }

    private var currentLocationButton: some View {
        AccentButtonView(label: "Use Current Location", systemImage: "location")
        {
            selected = nil
        }
    }

    private var selectionIndicator: some View {
        VStack(alignment: .trailing) {
            if selected != nil {
                PlannerChipView(
                    title: selected?.name
                        ?? locationManager.cityName,
                    iconName: "mappin.and.ellipse",
                    color: nil,
                    onTap: nil
                )
            } else {
                HStack(spacing: 6) {
                    Image(systemName: "location")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)

                    VStack(alignment: .leading) {
                        Text("Current Location")
                            .font(.system(size: 14, weight: .medium))

                        Text(locationManager.cityName)
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(Color(uiColor: .secondaryLabel))
                    }

                }
                .glassChip(color: nil, onTap: nil, height: 40)
            }
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    @ViewBuilder
    private func locationRow(
        title: String,
        subtitle: String?,
        isSelected: Bool,
        onTap: @escaping () -> Void
    ) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(title)
                    .font(.headline)

                if let subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark")
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .discreetListItem()
    }

    private func isLocationSelected(_ location: Location) -> Bool {
        guard let selected else {
            return false
        }

        return selected.latitude == location.latitude
            && selected.longitude == location.longitude
    }

    private func isSuggestionSelected(_ suggestion: MKLocalSearchCompletion)
        -> Bool
    {
        guard let selected else {
            return false
        }

        return selected.name == suggestion.title
            && selected.subtitle == suggestion.subtitle
    }

    private func suggestionId(_ suggestion: MKLocalSearchCompletion?) -> String?
    {
        guard let suggestion else { return nil }

        return "\(suggestion.title)-\(suggestion.subtitle)"
    }
}
