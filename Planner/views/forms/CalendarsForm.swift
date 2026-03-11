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
        "briefcase.fill",
        "airplane",
        "suitcase.fill",
        "popcorn",
        "globe.americas.fill",
        "birthday.cake.fill",
        "calendar",
        "dollarsign",
        "mountain.2.fill",
        "dog.fill",
        "basketball.fill",
    ]

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

    private func row(for calendar: EKCalendar) -> some View {
        HStack {
            Image(
                systemName: settings.hiddenCalendarIds
                    .contains(calendar.calendarIdentifier)
                    == false
                    ? "checkmark.circle" : "circle"
            )
            .imageScale(.large)
            .fontWeight(.light)
            .padding(.trailing, 6)
            .contentTransition(
                .symbolEffect(
                    .replace.magic(fallback: .replace)
                )
            )

            Text(calendar.title)

            Spacer()

            Menu {
                ForEach(systemImageNameOptions, id: \.self) {
                    systemImageName in
                    Button("", systemImage: systemImageName) {
                        modelContext.updateCalendarIcon(
                            in: settings,
                            for: calendar,
                            to: systemImageName
                        )
                    }
                }
            } label: {
                Image(
                    systemName: calendar.systemImageName(
                        settings: settings
                    )
                )
                .foregroundStyle(calendar.color)
            }
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
