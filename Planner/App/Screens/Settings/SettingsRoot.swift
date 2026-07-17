//
//  SettingsRoot.swift
//  Planner
//
//  Created by Alex Green on 1/4/26.
//

import EventKit
import SwiftData
import SwiftUI

struct SettingsRootView: View {
    let settings: Settings

    @AppStorage("appColorScheme") private var appColorScheme = AppColorScheme
        .dark

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var systemColorScheme
    @EnvironmentObject private var calendarService: CalendarService

    private var activeCalendarCount: String {
        String(
            calendarService.sortedCalendars.filter {
                !settings.hiddenCalendarIds.contains($0.calendarIdentifier)
            }.count
        )
    }

    private var appIconKey: String {
        "\(accentColor)_\(systemColorScheme)"
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    // MARK: App Theme

                    Picker("Theme", selection: $appColorScheme) {
                        ForEach(AppColorScheme.allCases, id: \.rawValue) {
                            colorScheme in
                            Text(colorScheme.rawValue.capitalized)
                                .tag(colorScheme)
                        }
                    }

                    // MARK: Accent Color

                    HStack {
                        Text(AccentColor.title)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        IconPickerView(
                            selectedIconConfig: IconConfig(
                                name: "square.fill",
                                primaryColor: accentColor.swiftUiColor,
                                scale: .large
                            ),
                            options: AccentColor.allCases.map { colorConfig in
                                IconConfig(
                                    name: colorConfig == accentColor
                                        ? "circle.fill" : "circle",
                                    primaryColor: colorConfig.swiftUiColor
                                )
                            },
                            numColumns: 3,
                            onTap: { config in
                                if let selected = AccentColor.allCases.first(
                                    where: {
                                        $0.swiftUiColor == config.primaryColor
                                    }
                                ) {
                                    accentColor = selected
                                }
                            }
                        )
                    }

                    // MARK: List Dividers

                    Toggle(
                        "Show List Dividers",
                        isOn: Binding(
                            get: { settings.showListDividers },
                            set: { settings.showListDividers = $0 }
                        )
                    )
                    .tint(accentColor.swiftUiColor)

                    // MARK: Toggle Transition Duration

                    NavigationLink {
                        ToggleTransitionFormView(settings: settings)
                    } label: {
                        HStack {
                            Text(ToggleTransitionDuration.title)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(
                                settings.toggleTransitionDuration.label
                            )
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Planner") {
                    // MARK: Home Location

                    NavigationLink {
                        LocationFormView(
                            variant: .home,
                            initialLocation: settings.homeLocation,
                            settings: settings,
                            saveSelection: {
                                modelContext.updateHomeLocation(
                                    in: settings,
                                    to: $0
                                )
                            }
                        )
                    } label: {
                        HStack {
                            Text("Home Location")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(
                                settings.homeLocation?.name
                                    ?? "Current Location"
                            )
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }
                    }

                    // MARK: Calendars

                    NavigationLink {
                        CalendarsFormView(settings: settings)
                    } label: {
                        HStack {
                            Text("Calendars")
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(
                                calendarService.hasCalendarAccess != true
                                    ? "No Access" : activeCalendarCount
                            )
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .disabled(calendarService.hasCalendarAccess != true)

                    // MARK: Keep Past Events Duration

                    NavigationLink {
                        KeepPastEventsFormView(settings: settings)
                    } label: {
                        HStack {
                            Text(KeepPastEventsDuration.title)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            Text(
                                settings.keepPastEventsDuration.label
                            )
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Settings")
        }

        // MARK: Update app icon when dependencies changes.

        .onChange(of: appIconKey) { _, _ in
            syncAppIconWithSettings(
                accentColor: accentColor,
                systemColorScheme: systemColorScheme
            )
        }
    }
}
