//
//  PlannerFilterToolbar.swift
//  Planner
//
//  Created by Alex Green on 4/3/26.
//

import EventKit
import SwiftUI

struct PlannerFilterToolbarView: ToolbarContent {
    @Binding var draftQuery: PlannerSearchQuery
    let filterCount: Int?
    let settings: Settings

    @EnvironmentObject private var calendarService: CalendarService

    private var hideCalendarSection: Bool {
        calendarService.hasCalendarAccess != true
    }

    // MARK: - Body

    var body: some ToolbarContent {
        if !hideCalendarSection {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Menu("", systemImage: "line.3.horizontal.decrease") {
                    calendarSection
                }
                .menuActionDismissBehavior(.disabled)
                .badge(filterCount != nil ? String(filterCount!) : nil)
            }
        }
    }

    // MARK: - View Builders

    private var calendarSection: some View {
        Section("Calendars") {
            ForEach(
                calendarService.sortedVisibleCalendars,
                id: \.calendarIdentifier
            ) {
                calendar in
                Toggle(
                    isOn: Binding(
                        get: {
                            draftQuery.calendarIds.contains(
                                calendar.calendarIdentifier
                            )
                        },
                        set: { isOn in
                            if isOn {
                                draftQuery.calendarIds.insert(
                                    calendar.calendarIdentifier
                                )
                            } else {
                                draftQuery.calendarIds.remove(
                                    calendar.calendarIdentifier
                                )
                            }
                        }
                    )
                ) {
                    HStack {
                        Image(
                            systemName: calendar.systemImageName(
                                settings: settings
                            )
                        )
                        .tint(calendar.color)

                        Text(calendar.title)
                    }
                }
            }
        }
    }
}
