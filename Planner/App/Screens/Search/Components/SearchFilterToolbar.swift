//
//  SearchFilterToolbar.swift
//  Planner
//
//  Created by Alex Green on 4/3/26.
//

import EventKit
import SwiftUI

struct SearchFilterToolbarView: ToolbarContent {
    @Binding var draftQuery: SearchQuery
    let settings: Settings

    @EnvironmentObject private var calendarService: CalendarService

    // MARK: - Body

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarLeading) {
            Menu("", systemImage: "line.3.horizontal.decrease") {
                timeFrameSection
                if calendarService.hasCalendarAccess == true {
                    calendarSection
                }
            }
            .menuActionDismissBehavior(.disabled)
        }
    }

    // MARK: - View Builders

    private var timeFrameSection: some View {
        Section("Timeframe") {
            Toggle(
                "Future",
                isOn: Binding(
                    get: {
                        !draftQuery.past
                    },
                    set: { _ in
                        draftQuery.past = false
                    }
                )
            )
            Toggle(
                "Past",
                isOn: Binding(
                    get: {
                        draftQuery.past
                    },
                    set: { _ in
                        draftQuery.past = true
                    }
                )
            )
        }
    }

    private var calendarSection: some View {
        Section("Calendars") {
            ForEach(calendarService.sortedVisibleCalendars, id: \.calendarIdentifier) {
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
