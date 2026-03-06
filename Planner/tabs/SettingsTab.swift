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

    @AppStorage("showListSeparators") private var showListSeparators: Bool =
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
    @EnvironmentObject private var deviceLocationManager: DeviceLocationManager

    var body: some View {
        NavigationStack {
            Form {
                Section {

                    // Accent Color
                    Picker(AccentColor.title, selection: $accentColor) {
                        ForEach(AccentColor.allCases, id: \.self) {
                            color in
                            Image(systemName: "circle.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(color.color)
                                .tag(color)
                        }
                    }
                    .pickerStyle(.menu)

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

                    // List Separators
                    Toggle("Show List Separators", isOn: $showListSeparators)
                        .tint(accentColor.color)

                } header: {
                    Text("Appearance")
                }
                .listSectionMargins(.bottom, 0)

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
                .listSectionMargins(.all, 0)

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
                    NavigationLink("Calendars") {
                        CalendarsFormView(settings: settings)
                    }

                    // Home Location
                    NavigationLink {
                        LocationSearchView(
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
                } header: {
                    Text("Planner")
                }
                .listSectionMargins(.top, 0)

            }
            .navigationTitle("Settings")
        }
    }

}
