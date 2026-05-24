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
        "leaf",
    ]

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var plannerSyncService: PlannerSyncService

    @State private var calendarStoreRefreshTask: Task<Void, Never>?
    
    // MARK: - Body

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
                .padding(.bottom, 16)
            }
        }
        .navigationTitle("Calendars")
        .navigationBarTitleDisplayMode(.inline)

        // MARK: Refresh the calendar store when the hidden calendars change.
        .onChange(of: settings.hiddenCalendarIds) { _, _ in
            scheduleCalendarStoreRefresh()
        }
    }

    // MARK: - View Builders

    private func row(for calendar: EKCalendar) -> some View {
        HStack {
            IconPickerView(
                selectedIconConfig: IconConfig(
                    name: calendar.systemImageName(settings: settings),
                    primaryColor: calendar.color,
                    secondaryColor: calendar.color
                ),
                options: systemImageNameOptions.map { option in
                    IconConfig(
                        name: option,
                        primaryColor: option
                            == calendar.systemImageName(settings: settings)
                            ? calendar.color : .label,
                        secondaryColor: .label
                    )
                },
                numColumns: 4,
                onTap: {
                    modelContext.updateCalendarIcon(
                        in: settings,
                        for: calendar,
                        to: $0.name
                    )
                }
            )

            Text(calendar.title)
                .frame(maxWidth: .infinity, alignment: .leading)

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
                try await Task.sleep(for: .milliseconds(5000))
                guard !Task.isCancelled else { return }

                calendarStore.refreshCalendarsAndAccess()
                plannerSyncService.rebuildCalendarData()
            } catch {}
        }
    }
}
