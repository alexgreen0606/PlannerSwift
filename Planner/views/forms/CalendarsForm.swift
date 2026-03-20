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
            ForEach(
                calendarStore.sortedCalendars,
                id: \.calendarIdentifier,
                content: row
            )
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
        let isActive = !settings.hiddenCalendarIds.contains(
            calendar.calendarIdentifier
        )
        HStack {
            Image(
                systemName: isActive ? "checkmark.circle" : "circle"
            )
            .foregroundStyle(isActive ? accentColor.color : Color.secondary)
            .imageScale(.large)
            .padding(.trailing, 6)
            .contentTransition(
                .symbolEffect(
                    .replace.magic(fallback: .replace)
                )
            )

            Text(calendar.title)

            Spacer()

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
        }
        .contentShape(Rectangle())
        .onTapGesture {
            modelContext.toggleCalendarVisibility(
                in: settings,
                for: calendar
            )
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
