//
//  Settings.swift
//  Planner
//
//  Created by Alex Green on 1/4/26.
//

import Combine
import EventKit
import SwiftData
import SwiftUI

struct SettingsTabView: View {

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
    @Query private var plannerSettingsList: [PlannerSettings]

    private var plannerSettings: PlannerSettings? {
        plannerSettingsList.first
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {

                    Picker(accentColor.title, selection: $accentColor) {
                        ForEach(AccentColor.allCases, id: \.self) {
                            option in
                            Image(systemName: "circle.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(option.swiftUIColor)
                                .tag(option)
                        }
                    }
                    .pickerStyle(.menu)

                    Picker(
                        toggleTransitionDuration.title,
                        selection: $toggleTransitionDuration
                    ) {
                        ForEach(ToggleTransitionDuration.allCases, id: \.self) {
                            scheme in
                            Text(scheme.label)
                                .tag(scheme)
                        }
                    }
                    .pickerStyle(.menu)

                    Toggle("Show List Separators", isOn: $showListSeparators)
                        .tint(accentColor.swiftUIColor)

                } header: {
                    Text("Appearance")
                }
                .listSectionMargins(.bottom, 0)

                Picker("App Theme", selection: $appColorScheme) {
                    ForEach(AppColorScheme.allCases, id: \.rawValue) {
                        scheme in
                        Text(scheme.rawValue.capitalized)
                            .tag(scheme)
                    }
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .listSectionMargins(.all, 0)

                Section {
                    Picker(
                        keepPastPlansDuration.title,
                        selection: $keepPastPlansDuration
                    ) {
                        ForEach(KeepPastPlansDuration.allCases, id: \.self) {
                            option in
                            Text(option.label)
                                .tag(option)
                        }
                    }
                    .pickerStyle(.menu)

                    Picker(
                        keepCanceledPlansDuration.title,
                        selection: $keepCanceledPlansDuration
                    ) {
                        ForEach(
                            KeepCanceledPlansDuration.allCases,
                            id: \.self
                        ) {
                            option in
                            Text(option.label)
                                .tag(option)
                        }
                    }
                    .pickerStyle(.menu)

                    Picker(
                        "Show End Events",
                        selection: $keepPastPlansDuration
                    ) {
                        // TODO: multi-day only / always
                    }
                    .pickerStyle(.menu)

                    NavigationLink("Calendars") {
                        CalendarsView()
                    }

                    NavigationLink("Home Location") {
                        LocationSearchView(
                            initialLocation: plannerSettings?.homeLocation,
                            initialLocationSource: plannerSettings?.homeLocation != nil ? .custom : .current,
                            title: "Edit Home Location",
                            mode: .home
                        ) { source, location in
                            guard let plannerSettings else {
                                return
                            }

                            plannerSettings.homeLocation = source == .custom ? location : nil

                            do {
                                try modelContext.save()
                            } catch {
                                assertionFailure(
                                    "Failed to save home location: \(error)"
                                )
                            }
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
