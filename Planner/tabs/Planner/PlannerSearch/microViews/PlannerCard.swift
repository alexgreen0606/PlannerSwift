//
//  PlannerCard.swift
//  Planner
//
//  Created by Alex Green on 12/16/25.
//

import EventKit
import SwiftUI

struct PlannerCard: View {
    let datestamp: String
    let allDayEvents: [EKEvent]
    let singleDayEvents: [EKEvent]
    let openPlanner: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            PlannerDateInfo(datestamp: datestamp, iconScale: 1.4)

            if !allDayEvents.isEmpty {
                PlannerChipSpreadView(
                    datestamp: datestamp,
                    events: allDayEvents,
                    showCountdown: false,
                    showWeather: false,
                    animation: nil,
                    openCalendarEventSheet: nil
                )
            }
            
            if !singleDayEvents.isEmpty {
                CalendarEventList(
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
