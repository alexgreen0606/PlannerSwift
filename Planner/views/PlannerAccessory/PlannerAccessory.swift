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
    var animation: Namespace.ID
    let openTodayPlanner: () -> Void

    @EnvironmentObject var todaystampManager: TodaystampManager
    @State var navigationManager = NavigationManager.shared
    @EnvironmentObject var calendarEventStore: CalendarEventStore
    @Environment(\.tabViewBottomAccessoryPlacement) private var placement

    @Environment(\.modelContext) private var modelContext

    @Query private var planners: [Planner]

    private var eventsForToday: [EKEvent] {
        return calendarEventStore.allDayEventsByDatestamp[
            todaystampManager.todaystamp
        ] ?? []
    }
    
    var eventCount: Int {
        23
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

                    Text(eventCount == 0 ? "No plans" : "\(eventCount) plan\(eventCount == 1 ? "" : "s")")
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
    }
}

#Preview {
    ContentView()
}
