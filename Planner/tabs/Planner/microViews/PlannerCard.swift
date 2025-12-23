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
    let openCalendarEvent: (EKEvent) -> Void
    let openPlanner: () -> Void

    var date: Date? {
        datestamp.date
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading) {
                HStack(alignment: .top) {
                    Text(date?.header ?? datestamp)
                        .font(.headline)
                        .fontWeight(.bold)

                    Spacer()

                    Text(date?.daysUntil ?? "")
                        .font(.caption)
                        .foregroundStyle(Color(uiColor: .secondaryLabel))
                }

                Text(date?.subHeader ?? "")
                    .font(.subheadline)
                    .foregroundStyle(Color(uiColor: .secondaryLabel))
            }

            if !allDayEvents.isEmpty {
                PlannerChipSpreadView(
                    datestamp: datestamp,
                    events: allDayEvents,
                    showCountdown: false,
                    chipAnimation: chipAnimation,
                    openCalendarEvent: openCalendarEvent
                )
            }

            if !singleDayEvents.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(singleDayEvents, id: \.self) { event in
                        HStack(alignment: .top, spacing: 12) {
                            Text(event.title)
                                .font(.system(size: 15))
                                .foregroundStyle(Color(uiColor: .label))

                            Spacer()

                            let (timeValue, indicator) = event.startDate
                                .timeValues
                            TimeValue(
                                time: timeValue,
                                indicator: indicator,
                                detail: nil,
                                disabled: false,
                                color: Color(event.calendar.cgColor)
                            ) {

                            }
                        }

                        if event.eventIdentifier
                            != singleDayEvents.last!.eventIdentifier
                        {
                            DashedDivider()
                        }
                    }
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: openPlanner)
        .padding(.vertical, 8)
        .containerShape(
            .rect(cornerRadius: 24)
        )
    }
}
