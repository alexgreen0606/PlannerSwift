//
//  CalendarsForm.swift
//  Planner
//
//  Created by Alex Green on 1/22/26.
//

import Combine
import EventKit
import SwiftData
import SwiftUI

// Clean

struct CalendarsFormView: View {
    let settings: PlannerSettings

    private let systemImageNameOptions: [String] = [
        "briefcase",
        "airplane",
        "suitcase",
        "popcorn",
        "globe.americas.fill",
        "birthday.cake",
        "calendar",
        "dollarsign",
        "mountain.2",
        "dog",
        "cat",
        "basketball",
        "gamecontroller",
        "american.football",
        "camera",
        "figure.2",
        "figure.strengthtraining.traditional",
    ]

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var calendarStore: CalendarStore

    @State private var calendarStoreRefreshTask: Task<Void, Never>?

    var body: some View {
        List {
            Section {
                ForEach(
                    calendarStore.sortedCalendars,
                    id: \.calendarIdentifier,
                    content: row
                )
            } footer: {
                Text(
                    "Turn off a calendar to hide its events throughout the app."
                )
            }

            // MARK: BOTTOM PADDING
            Section {
                Color.clear.frame(height: 16)
            }
            .discreetListItem()
        }
        .navigationTitle("Calendars")
        .navigationBarTitleDisplayMode(.inline)

        // Refresh the calendar store when the hidden calendars change.
        .onChange(of: settings.hiddenCalendarIds) { _, _ in
            scheduleCalendarStoreRefresh()
        }
    }

    // MARK: - View Builders

    @ViewBuilder
    private func row(for calendar: EKCalendar) -> some View {
        HStack {
            IconSelectorView(
                selectedIconConfig: IconConfig(
                    name: calendar.systemImageName(settings: settings),
                    primaryColor: calendar.color
                ),
                options: systemImageNameOptions.map {
                    let isSelected =
                        $0 == calendar.systemImageName(settings: settings)
                    return IconConfig(
                        name: $0,
                        primaryColor: isSelected ? calendar.color : .label,
                        secondaryColor: .label
                    )
                },
                numColumns: 4,
                onTap: { config in
                    modelContext.updateCalendarIcon(
                        in: settings,
                        for: calendar,
                        to: config.name
                    )
                }
            )

            Text(calendar.title)

            Spacer()

            Toggle(
                "",
                isOn: Binding(
                    get: {
                        !settings.hiddenCalendarIds.contains(
                            calendar.calendarIdentifier
                        )
                    },
                    set: { _ in
                        modelContext.toggleCalendarVisibility(
                            in: settings,
                            for: calendar
                        )
                    }
                )
            )
            .labelsHidden()
            .tint(accentColor.color)

        }
    }

    // MARK: - Functions

    private func scheduleCalendarStoreRefresh() {
        calendarStoreRefreshTask?.cancel()

        calendarStoreRefreshTask = Task {
            do {
                try await Task.sleep(for: .milliseconds(1000))
                guard !Task.isCancelled else { return }

                calendarStore.attemptFreshLoad(
                    hiddenCalendarIds: settings.hiddenCalendarIds
                )
            } catch {
            }
        }
    }

}
