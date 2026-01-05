//
//  PlannerCard.swift
//  Planner
//
//  Created by Alex Green on 12/16/25.
//

import EventKit
import SwiftUI

struct PlannerCardView: View {
    let datestamp: String
    let iconMap: [String: String]
    let openPlanner: () -> Void
    
    @EnvironmentObject var calendarEventStore: CalendarStore

    private var allDayEvents: [EKEvent] {
        calendarEventStore.allDayEventsByDatestamp[
            datestamp
        ] ?? []
    }

    private var singleDayEvents: [EKEvent] {
        calendarEventStore.singleDayEventsByDatestamp[
            datestamp
        ] ?? []
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PlannerDateInfoView(datestamp: datestamp, iconScale: 1.4)

            if !allDayEvents.isEmpty {
                PlannerChipSpreadView(
                    datestamp: datestamp,
                    events: allDayEvents,
                    showCountdown: false,
                    showWeather: false,
                    iconMap: iconMap,
                    animation: nil,
                    openCalendarEventSheet: nil
                )
            }
            
            if !singleDayEvents.isEmpty {
                CalendarEventListView(
                    datestamp: datestamp,
                    events: singleDayEvents
                )
            }
        }
        .listRowBackground(Color.appBackground)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture(perform: openPlanner)
        .padding(.vertical, 8)
    }
}
