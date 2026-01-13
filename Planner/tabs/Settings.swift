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

// TODO: debounce re-load the calendar store when the settings change

struct SettingsView: View {
    @AppStorage("themeColor") var themeColor: ThemeColorOption =
        ThemeColorOption.blue
    @AppStorage("showListSeparators") private var showListSeparators: Bool =
        true

    @Environment(\.modelContext) private var modelContext
    @Query private var settingList: [CalendarSettings]
    @State private var settings: CalendarSettings?

    @EnvironmentObject var calendarStore: CalendarStore

    @State private var calendarRefreshDebounce: Task<Void, Never>?

    private var iconOptions: [String] = [
        "briefcase.fill",
        "airplane",
        "suitcase.fill",
        "popcorn",
        "globe.americas.fill",
        "birthday.cake.fill",
        "calendar",
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Accent Color", selection: $themeColor) {
                        ForEach(ThemeColorOption.allCases, id: \.self) {
                            option in
                            Image(systemName: "circle.fill")
                                .symbolRenderingMode(.palette)
                                .foregroundStyle(option.swiftUIColor)
                                .tag(option)
                        }
                    }
                    .pickerStyle(.menu)

                    Toggle("List separators", isOn: $showListSeparators)
                        .tint(themeColor.swiftUIColor)
                } header: {
                    Text("Style")
                }

                Section {
                    ForEach(
                        calendarStore.sortedCalendars,
                        id: \.calendarIdentifier
                    ) { calendar in
                        HStack {
                            Image(
                                systemName: settings?.hiddenCalendarIds
                                    .contains(calendar.calendarIdentifier)
                                    == false
                                    ? "checkmark.circle" : "circle"
                            )
                            .foregroundStyle(Color(calendar.cgColor))
                            .contentShape(Rectangle())
                            .contentTransition(
                                .symbolEffect(
                                    .replace.magic(fallback: .replace)
                                )
                            )
                            .onTapGesture {
                                guard let settings else { return }

                                if settings.hiddenCalendarIds.contains(
                                    calendar.calendarIdentifier
                                ) {
                                    settings.hiddenCalendarIds.remove(
                                        calendar.calendarIdentifier
                                    )
                                } else {
                                    settings.hiddenCalendarIds.insert(
                                        calendar.calendarIdentifier
                                    )
                                }

                                try! modelContext.save()
                            }

                            Text(calendar.title)

                            Spacer()

                            Menu {
                                ForEach(iconOptions, id: \.self) { iconName in
                                    Button("", systemImage: iconName) {
                                        guard let settings else { return }

                                        settings.iconMap[
                                            calendar.calendarIdentifier
                                        ] = iconName

                                        try! modelContext.save()
                                    }
                                }
                            } label: {
                                Image(
                                    systemName: settings?.iconMap[
                                        calendar.calendarIdentifier
                                    ] ?? calendar.iconName
                                )
                                .foregroundStyle(Color(calendar.cgColor))
                            }
                        }
                    }
                } header: {
                    Text("Calendars")
                }
            }
            .navigationTitle("Settings")
            // Load in the settings on mount.
            .task {
                settings = modelContext.ensureCalendarSettings(
                    settings: settingList
                )
            }
            // Refresh the calendar when the hidden calendars change.
            .onChange(of: settings?.hiddenCalendarIds) { _, _ in
                scheduleCalendarRefreshDebounce()
            }
        }
    }

    private func scheduleCalendarRefreshDebounce() {
        calendarRefreshDebounce?.cancel()

        calendarRefreshDebounce = Task {
            do {
                try await Task.sleep(for: .milliseconds(500))
                guard !Task.isCancelled else { return }

                // Refresh the calendar data.
                calendarStore.refresh(
                    hiddenCalendarIds: settings?.hiddenCalendarIds ?? []
                )
            } catch {
                // Task cancelled — do nothing.
            }
        }
    }

}
