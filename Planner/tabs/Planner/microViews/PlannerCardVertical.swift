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
    let datestamp: String
    let allDayEvents: [EKEvent]
    let singleDayEvents: [EKEvent]
    var chipAnimation: Namespace.ID
    let openCalendarEventSheet: (EKEvent, String) -> Void
    let openPlanner: () -> Void

    var date: Date? {
        datestamp.date
    }

    @EnvironmentObject var todaystampManager: TodaystampManager

    @Environment(\.modelContext) private var modelContext
    @Query private var planners: [Planner]
    @State private var planner: Planner?

    var planCountLabel: String {
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
        chipAnimation: Namespace.ID,
        openCalendarEventSheet: @escaping (EKEvent, String) -> Void,
        openPlanner: @escaping () -> Void
    ) {
        self.datestamp = datestamp
        self.allDayEvents = allDayEvents
        self.singleDayEvents = singleDayEvents
        self.chipAnimation = chipAnimation
        self.openCalendarEventSheet = openCalendarEventSheet
        self.openPlanner = openPlanner

        _planners = Query(
            filter: #Predicate<Planner> {
                $0.datestamp == datestamp
            }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                PlannerIcon(datestamp: datestamp, scale: 1.4)
                VStack(alignment: .leading) {
                    Text(date?.weekday ?? datestamp)
                        .font(.headline)
                        .fontWeight(.bold)

                    Text(datestamp.date?.countdown ?? "")
                        .font(.footnote)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if !allDayEvents.isEmpty {
                PlannerChipSpreadView(
                    datestamp: datestamp,
                    events: allDayEvents,
                    key: "PlannerCardVertical",
                    showCountdown: false,
                    showWeather: false,
                    center: false,
                    chipAnimation: chipAnimation,
                    openCalendarEventSheet: openCalendarEventSheet
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
                .fill(Color.plannerCardVerticalBackground)
        )
        .opacity(todaystampManager.todaystamp == datestamp ? 1 : 0.84)
        .onTapGesture(perform: openPlanner)
        .task {
            ensurePlanner()
        }
    }

    // TODO: move up in tree for PlannerCardVertical
    @MainActor
    private func ensurePlanner() {
        if let storagePlanner = planners.first {
            planner = storagePlanner
        } else if planner == nil {
            // Only create if planner doesn't exist yet.
            let newPlanner = Planner(
                datestamp: datestamp
            )
            modelContext.insert(newPlanner)
            try! modelContext.save()

            planner = newPlanner
        }
    }
}
