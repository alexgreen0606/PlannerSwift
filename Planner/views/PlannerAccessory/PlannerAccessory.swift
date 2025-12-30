//
//  PlannerAccessory.swift
//  Planner
//
//  Created by Alex Green on 12/21/25.
//

import EventKit
import SwiftData
import SwiftUI

struct PlannerAccessoryView: View {
    let todaystamp: String
    var animation: Namespace.ID
    let openTodayPlanner: () -> Void

    @EnvironmentObject var todaystampManager: TodaystampWatcher
    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var calendarEventStore: CalendarEventStore
    @Environment(\.tabViewBottomAccessoryPlacement) private var placement

    @Environment(\.modelContext) private var modelContext
    @Query private var planners: [Planner]
    @State private var planner: Planner?

    private var eventsForToday: [EKEvent] {
        return calendarEventStore.allDayEventsByDatestamp[
            todaystampManager.todaystamp
        ] ?? []
    }
    
    var planCountLabel: String {
        let planCount = planner?.events.filter{ !$0.isChecked }.count ?? 0

        if planCount == 0 {
            if eventsForToday.count > 0 {
                return "No more plans"
            }
            return "No plans"
        }

        return "\(planCount) plan\(planCount == 1 ? "" : "s")"
    }
    
    init(todaystamp: String, animation: Namespace.ID, openTodayPlanner: @escaping () -> Void) {
        self.animation = animation
        self.todaystamp = todaystamp
        self.openTodayPlanner = openTodayPlanner
        
        _planners = Query(
            filter: #Predicate<Planner> {
                $0.datestamp == todaystamp
            }
        )
    }

    var body: some View {
        HStack(spacing: 6) {
            PlannerIcon(datestamp: todaystampManager.todaystamp, scale: 1)

            VStack(alignment: .leading, spacing: 0) {
                Text(todaystampManager.todaystamp.date?.dynamicHeader ?? "")
                    .font(.callout)
                    .matchedTransitionSource(
                        id: "PLANNER_ACCESSORY",
                        in: animation
                    )

                HStack(alignment: .center, spacing: 6) {
                    if !eventsForToday.isEmpty {
                        HStack(alignment: .bottom, spacing: 2) {
                            ForEach(eventsForToday, id: \.self) { event in
                                Image(systemName: event.calendar.iconName)
                                    .font(.caption)
                                    .imageScale(.small)
                                    .foregroundStyle(
                                        Color(event.calendar.cgColor)
                                    )
                            }
                        }

                        Divider().frame(height: 10)
                    }

                    Text(planCountLabel)
                        .font(.caption2)
                        .foregroundStyle(
                            Color(uiColor: .secondaryLabel)
                        )
                }
            }
            .lineLimit(1)

            Spacer()

            HStack(alignment: .center) {
                if placement != .inline {
                    VStack(alignment: .trailing, spacing: 0) {
                        Text("Sunny")
                            .font(.caption)

                        HStack(alignment: .center, spacing: 4) {
                            Text("76°")
                                .font(.caption2)

                            Divider().frame(height: 10)

                            Text("64°")
                                .font(.caption2)
                        }
                        .foregroundStyle(
                            Color(uiColor: .secondaryLabel)
                        )
                    }
                }

                Image(systemName: "sun.max.fill")
                    .imageScale(.medium)
                    .foregroundStyle(.yellow)
            }
            .frame(maxHeight: .infinity)
        }
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
        .onTapGesture(perform: openTodayPlanner)
        .task {
            guard planner == nil else { return }

            planner = modelContext.ensurePlanner(
                planners: planners,
                datestamp: todaystamp
            )
        }
    }
}
