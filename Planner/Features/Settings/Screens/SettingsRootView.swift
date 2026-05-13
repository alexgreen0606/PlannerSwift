//
//  SettingsTab.swift
//  Planner
//
//  Created by Alex Green on 1/4/26.
//

import Combine
import EventKit
import SwiftData
import SwiftUI

struct SettingsRootView: View {
    let settings: PlannerSettings

    @AppStorage("appColorScheme") private var appColorScheme = AppColorScheme
        .dark

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @AppStorage("showListDividers") private var showListDividers: Bool =
        true

    @AppStorage("keepPastEventsDuration") private var keepPastEventsDuration:
        KeepPastEventsDuration =
            KeepPastEventsDuration.oneMonth

    @AppStorage("keepCanceledEventsDuration") private
        var keepCanceledEventsDuration: KeepCanceledEventsDuration =
            KeepCanceledEventsDuration.startOfDay

    @AppStorage("toggleTransitionDuration") private
        var toggleTransitionDuration: ToggleTransitionDuration =
            ToggleTransitionDuration.threeSeconds

    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var systemColorScheme
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var plannerSyncStore: PlannerSyncStore

    private var activeCalendarCount: String {
        String(
            calendarStore.sortedCalendars.filter {
                !settings.hiddenCalendarIds.contains($0.calendarIdentifier)
            }.count
        )
    }

    var body: some View {
        NavigationStack {
            Form {

                Section {

                    // App Theme
                    Picker("Theme", selection: $appColorScheme) {
                        ForEach(AppColorScheme.allCases, id: \.rawValue) {
                            colorScheme in
                            Text(colorScheme.rawValue.capitalized)
                                .tag(colorScheme)
                        }
                    }

                    // Accent Color
                    HStack {
                        Text(AccentColor.title)
                        Spacer()
                        IconSelectorView(
                            selectedIconConfig: IconConfig(
                                name: "square.fill",
                                primaryColor: accentColor.color
                            ),
                            options: AccentColor.allCases.map {
                                let isSelected = $0 == accentColor
                                return IconConfig(
                                    name: isSelected ? "circle.fill" : "circle",
                                    primaryColor: $0.color
                                )
                            },
                            numColumns: 3,
                            isLargeIcon: true,
                            onTap: { config in
                                if let selected = AccentColor.allCases.first(
                                    where: { $0.color == config.primaryColor })
                                {
                                    accentColor = selected
                                }
                            }
                        )
                    }

                    // List Separators
                    Toggle("Show List Separators", isOn: $showListDividers)
                        .tint(accentColor.color)

                    // Toggle Transition Duration
                    NavigationLink {
                        ToggleTransitionFormView()
                    } label: {
                        HStack {
                            Text(ToggleTransitionDuration.title)
                            Spacer()
                            Text(
                                toggleTransitionDuration.label
                            )
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }
                    }

                }

                Section("Planner") {

                    // Home Location
                    NavigationLink {
                        LocationSearchFormView(
                            title: "Edit Home Location",
                            mode: .home,
                            settings: settings,
                            initialLocation: settings.homeLocation,
                        ) { location in
                            modelContext.updateHomeLocation(
                                in: settings,
                                to: location
                            )
                        }
                    } label: {
                        HStack {
                            Text("Home Location")
                            Spacer()
                            Text(
                                settings.homeLocation?.name
                                    ?? "Current Location"
                            )
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }
                    }

                    // Calendars
                    NavigationLink {
                        CalendarsFormView(settings: settings)
                    } label: {
                        HStack {
                            Text("Calendars")
                            Spacer()
                            Text(
                                calendarStore.accessDenied != false
                                    ? "No Access" : activeCalendarCount
                            )
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .disabled(calendarStore.accessDenied != false)

                    // Keep Past Events Duration
                    NavigationLink {
                        KeepPastEventsFormView()
                    } label: {
                        HStack {
                            Text(KeepPastEventsDuration.title)
                            Spacer()
                            Text(
                                keepPastEventsDuration.label
                            )
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }
                    }

                    // Keep Canceled Events Duration
                    NavigationLink {
                        KeepCanceledEventsFormView()
                    } label: {
                        HStack {
                            Text(KeepCanceledEventsDuration.title)
                            Spacer()
                            Text(
                                keepCanceledEventsDuration.label
                            )
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }
                    }

                }

            }
            .navigationTitle("Settings")
        }
        .onChange(of: accentColor) { _, _ in
            syncAppIconWithSettings(
                accentColor: accentColor,
                systemColorScheme: systemColorScheme
            )
        }
        .onChange(of: systemColorScheme) { _, _ in
            syncAppIconWithSettings(
                accentColor: accentColor,
                systemColorScheme: systemColorScheme
            )
        }
    }

}
