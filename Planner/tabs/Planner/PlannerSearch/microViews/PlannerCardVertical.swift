//
//  PlannerCardVertical.swift
//  Planner
//
//  Created by Alex Green on 12/25/25.
//

import EventKit
import SwiftData
import SwiftDate
import SwiftUI
import WrappingHStack

struct PlannerCardVertical: View {
    private let datestamp: String
    private let allDayEvents: [EKEvent]
    private let singleDayEvents: [EKEvent]
    private let openPlanner: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Query private var planners: [Planner]
    @State private var planner: Planner?

    @EnvironmentObject var todaystampManager: TodaystampWatcher

    private var planCountLabel: String {
        let planCount = planner?.events.filter { !$0.isChecked }.count ?? 0

        if planCount == 0 {
            if singleDayEvents.count > 0 {
                return "No more plans"
            }
            return "No plans"
        }

        return "\(planCount) plan\(planCount == 1 ? "" : "s")"
    }

    init(
        datestamp: String,
        allDayEvents: [EKEvent],
        singleDayEvents: [EKEvent],
        openPlanner: @escaping () -> Void
    ) {
        self.datestamp = datestamp
        self.allDayEvents = allDayEvents
        self.singleDayEvents = singleDayEvents
        self.openPlanner = openPlanner

        _planners = Query(
            filter: #Predicate<Planner> {
                $0.datestamp == datestamp
            }
        )
    }

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

            VStack {
                Text(planCountLabel)
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(uiColor: .tertiaryLabel))
            }
            .frame(maxHeight: .infinity)
            .frame(maxWidth: .infinity, alignment: .center)

            HStack(alignment: .bottom) {
                HStack(alignment: .center, spacing: 6) {
                    Image(systemName: "cloud.snow.fill")
                        .symbolRenderingMode(.multicolor)
                        .imageScale(.small)

                    Text("Snow flurries")
                        .font(.caption2)
                }

                Spacer()

                HStack(alignment: .center, spacing: 4) {
                    Text("76°")
                        .font(.caption2)
                    Divider().frame(height: 16)
                    Text("62°")
                        .font(.caption2)
                }
            }
        }
        .padding()
        .frame(width: 220)
        .frame(maxHeight: .infinity, alignment: .top)
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color.cardBackground)
        )
        .onTapGesture(perform: openPlanner)
        .task {
            guard planner == nil else { return }

            planner = modelContext.ensurePlanner(
                planners: planners,
                datestamp: datestamp
            )
        }
    }
}
