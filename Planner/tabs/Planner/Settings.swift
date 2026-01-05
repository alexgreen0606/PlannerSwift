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

    @Environment(\.modelContext) private var modelContext
    @Query private var settingList: [CalendarSettings]
    @State private var settings: CalendarSettings?

    @EnvironmentObject var calendarEventStore: CalendarEventStore

    var iconOptions: [String] = [
        "briefcase.fill",
        "airplane",
        "suitcase.fill",
        "popcorn",
        "globe.americas.fill",
        "birthday.cake.fill",
        "calendar",
    ]

    var sortedCalendars: [EKCalendar] {
        Array(calendarEventStore.calendarsById.values)
            .sorted {
                $0.title.localizedCaseInsensitiveCompare($1.title)
                    == .orderedAscending
            }
    }

    var body: some View {
        Form {
            Section {

            }

            Section {
                ForEach(
                    sortedCalendars,
                    id: \.calendarIdentifier
                ) { calendar in
                    HStack {
                        Image(
                            systemName: settings?.hiddenCalendarIds
                                .contains(calendar.calendarIdentifier) == false
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
        .task {
            settings = modelContext.ensureCalendarSettings(
                settings: settingList
            )
        }
    }
}
