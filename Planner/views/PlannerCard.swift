//
//  PlannerCard.swift
//  Planner
//
//  Created by Alex Green on 12/16/25.
//

import EventKit
import SwiftUI
import SwiftDate

struct PlannerCardView: View {
    let datestamp: String
    let iconMap: [String: String]
    let isEventChecked: (EKEvent?) -> Bool
    let openPlanner: () -> Void

    @EnvironmentObject private var calendarEventStore: CalendarStore

    private var allDayEvents: [EKEvent] {
        calendarEventStore.allDayEventsByDatestamp[
            datestamp
        ] ?? []
    }

    private var singleDayEvents: [PlannerEvent] {
        let events =
            (calendarEventStore
            .singleDayEventsByDatestamp[datestamp] ?? []).filter {
                !isEventChecked($0)
            }

        // TODO: is correct date passed here?
        return events.enumerated().map { index, calEvent in
            PlannerEvent(
                date: calEvent.startDate,
                calendarEvent: calEvent,
                sortIndex: Double(index),
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            // TODO: pass correct region here
            PlannerDateInfoView(datestamp: datestamp, region: .local, isSoon: false)

            PreviewCalendarEventListView(events: allDayEvents, iconMap: iconMap)

            PreviewPlannerEventListView(
                datestamp: datestamp,
                events: singleDayEvents,
                hideLastDivider: true
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture(perform: openPlanner)
        .padding(.vertical, 8)
        .listRowBackground(Color.clear)
        .alignmentGuide(.listRowSeparatorLeading) { d in
            d[.leading]
        }
    }
}
