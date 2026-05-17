//
//  PlannerSearchToolbar.swift
//  Planner
//
//  Created by Alex Green on 4/3/26.
//

import EventKit
import SwiftUI

struct PlannerSearchToolbar: ToolbarContent {
    @Binding var filterPast: Bool
    @Binding var filteredCalendarIds: Set<String>
    let settings: PlannerSettings

    @EnvironmentObject private var calendarStore: CalendarStore

    private var sortedCalendars: [EKCalendar] {
        calendarStore.sortedCalendars.filter {
            !settings.hiddenCalendarIds.contains(
                $0.calendarIdentifier
            )
        }
    }

    var body: some ToolbarContent {
        if calendarStore.accessDenied == false {
            ToolbarItemGroup(placement: .topBarLeading) {
                Menu {
                    Section("Timeframe") {
                        Toggle(
                            "Upcoming",
                            isOn: Binding(
                                get: {
                                    !filterPast
                                },
                                set: { _ in
                                    filterPast.toggle()
                                }
                            )
                        )
                        Toggle(
                            "Past",
                            isOn: $filterPast
                        )
                    }

                    Section("Calendars") {
                        ForEach(sortedCalendars, id: \.calendarIdentifier) {
                            calendar in
                            Toggle(
                                isOn: Binding(
                                    get: {
                                        filteredCalendarIds.contains(
                                            calendar.calendarIdentifier
                                        )
                                    },
                                    set: { isOn in
                                        if isOn {
                                            filteredCalendarIds.insert(
                                                calendar.calendarIdentifier
                                            )
                                        } else {
                                            filteredCalendarIds.remove(
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
                } label: {
                    Image(systemName: "line.3.horizontal.decrease")
                }
                .menuActionDismissBehavior(.disabled)
            }
        }
    }
}
