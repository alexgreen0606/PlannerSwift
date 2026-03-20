//
//  SettingsTab.swift
//  Planner
//
//  Created by Alex Green on 1/4/26.
//

// Clean

import Combine
import EventKit
import SwiftData
import SwiftUI

struct SettingsTabView: View {
    let settings: PlannerSettings

    @AppStorage("appColorScheme") private var appColorScheme = AppColorScheme
        .system

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @AppStorage("showListDividers") private var showListDividers: Bool =
        true

    @AppStorage("keepPastPlansDuration") private var keepPastPlansDuration:
        KeepPastPlansDuration =
            KeepPastPlansDuration.oneMonth

    @AppStorage("keepCanceledPlansDuration") private
        var keepCanceledPlansDuration: KeepCanceledPlansDuration =
            KeepCanceledPlansDuration.startOfDay

    @AppStorage("toggleTransitionDuration") private
        var toggleTransitionDuration: ToggleTransitionDuration =
            ToggleTransitionDuration.threeSeconds

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var deviceLocationManager: DeviceLocationManager

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

                // App Theme
                Picker("App Theme", selection: $appColorScheme) {
                    ForEach(AppColorScheme.allCases, id: \.rawValue) {
                        colorScheme in
                        Text(colorScheme.rawValue.capitalized)
                            .tag(colorScheme)
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)

                Section {

                    // Accent Color
                    HStack {
                        Text(AccentColor.title)
                        Spacer()
                        IconSelectorView(
                            selectedIconConfig: IconConfig(
                                name: "circle.fill",
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
                    Picker(
                        ToggleTransitionDuration.title,
                        selection: $toggleTransitionDuration
                    ) {
                        ForEach(ToggleTransitionDuration.allCases, id: \.self) {
                            duration in
                            Text(duration.label)
                                .tag(duration)
                        }
                    }
                    .pickerStyle(.menu)

                }
                .listSectionMargins(.top, 0)

                Section {

                    // Keep Past Plans Duration
                    Picker(
                        KeepPastPlansDuration.title,
                        selection: $keepPastPlansDuration
                    ) {
                        ForEach(KeepPastPlansDuration.allCases, id: \.self) {
                            duration in
                            Text(duration.label)
                                .tag(duration)
                        }
                    }
                    .pickerStyle(.menu)

                    // Keep Canceled Plans Duration
                    Picker(
                        KeepCanceledPlansDuration.title,
                        selection: $keepCanceledPlansDuration
                    ) {
                        ForEach(
                            KeepCanceledPlansDuration.allCases,
                            id: \.self
                        ) {
                            duration in
                            Text(duration.label)
                                .tag(duration)
                        }
                    }
                    .pickerStyle(.menu)

                    // Calendars
                    NavigationLink {
                        CalendarsFormView(settings: settings)
                    } label: {
                        HStack {

                            Text("Calendars")

                            Spacer()

                            Text(
                                activeCalendarCount
                            )
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        }
                    }

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
                                settings.homeLocationLabel
                            )
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        }
                    }
                } header: {
                    Text("Planner")
                }
                .listSectionMargins(.top, 0)

            }
            .navigationTitle("Settings")
        }
    }

}
