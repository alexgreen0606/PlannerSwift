//
//  PlannerAccessory.swift
//  Planner
//
//  Created by Alex Green on 12/21/25.
//

import EventKit
import SwiftData
import SwiftUI
import WeatherKit

struct PlannerAccessoryView: View {
    private var todaystamp: String
    private var animation: Namespace.ID
    private let openTodayPlanner: () -> Void

    @Environment(\.tabViewBottomAccessoryPlacement) private var placement

    @Environment(\.modelContext) private var modelContext
    @Query private var planners: [Planner]
    @State private var planner: Planner?

    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var calendarEventStore: CalendarStore
    @ObservedObject var weatherStore = WeatherStore.shared

    private var weatherData: DayWeather? {
        weatherStore.dayWeatherByDatestamp[todaystamp]
    }

    private var allDayEvents: [EKEvent] {
        return calendarEventStore.allDayEventsByDatestamp[
            todaystamp
        ] ?? []
    }

    private var planCountLabel: String {
        let planCount = planner?.events.filter { !$0.isChecked }.count ?? 0

        if planCount == 0 {
            if allDayEvents.count > 0 {
                return "No more plans"
            }
            return "No plans"
        }

        return "\(planCount) plan\(planCount == 1 ? "" : "s")"
    }

    init(
        todaystamp: String,
        animation: Namespace.ID,
        openTodayPlanner: @escaping () -> Void
    ) {
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
            PlannerIcon(datestamp: todaystamp, scale: 1)

            VStack(alignment: .leading, spacing: 0) {
                Text(todaystamp.date?.weekday ?? "")
                    .font(.callout)
                    .matchedTransitionSource(
                        id: "PLANNER_ACCESSORY",
                        in: animation
                    )

                HStack(alignment: .center, spacing: 6) {
                    if !allDayEvents.isEmpty {
                        HStack(alignment: .bottom, spacing: 2) {
                            ForEach(allDayEvents, id: \.self) { event in
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
                if placement != .inline && weatherData != nil {
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(weatherData?.condition.description ?? "")
                            .font(.caption)

                        HStack(alignment: .center, spacing: 4) {
                            Text(weatherData?.highTempString ?? "")
                                .font(.caption2)

                            Divider().frame(height: 10)

                            Text(weatherData?.lowTempString ?? "")
                                .font(.caption2)
                        }
                        .foregroundStyle(
                            Color(uiColor: .secondaryLabel)
                        )
                    }
                }

                Image(systemName: weatherData?.symbolName ?? "")
                    .imageScale(.medium)
                    .foregroundStyle(.yellow)
            }
            .frame(maxHeight: .infinity)
        }
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
        .onTapGesture(perform: openTodayPlanner)
        .task {
            planner = modelContext.ensurePlanner(
                planners: planners,
                datestamp: todaystamp
            )
        }
    }
}
