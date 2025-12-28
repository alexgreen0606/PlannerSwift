//
//  PlannerCard.swift
//  Planner
//
//  Created by Alex Green on 12/16/25.
//

import EventKit
import SwiftDate
import SwiftUI
import WrappingHStack

struct PlannerCard: View {
    let datestamp: String
    let allDayEvents: [EKEvent]
    let singleDayEvents: [EKEvent]
    var chipAnimation: Namespace.ID
    let openCalendarEventSheet: (EKEvent, String) -> Void
    let openPlanner: () -> Void

    var date: Date? {
        datestamp.date
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading) {
                Text(date?.shortDate ?? datestamp)
                    .font(.headline)
                    .fontWeight(.bold)

                Text(date?.weekday ?? "")
                    .font(.subheadline)
                    .foregroundStyle(Color(uiColor: .secondaryLabel))
            }

            if !allDayEvents.isEmpty {
                PlannerChipSpreadView(
                    datestamp: datestamp,
                    events: allDayEvents,
                    key: "PlannerCard",
                    showCountdown: false,
                    showWeather: false,
                    center: false,
                    chipAnimation: chipAnimation,
                    openCalendarEventSheet: openCalendarEventSheet
                )
            }
            
            if !singleDayEvents.isEmpty {
                CalendarEventList(datestamp: datestamp, events: singleDayEvents)
            }
        }
        .listRowBackground(Color.appBackground)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture(perform: openPlanner)
        .padding(.vertical, 8)
    }
}
