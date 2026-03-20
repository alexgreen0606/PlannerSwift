////
////  PlannerAccessory.swift
////  Planner
////
////  Created by Alex Green on 12/21/25.
////
//
//import EventKit
//import SwiftData
//import SwiftUI
//import WeatherKit
//
//struct PlannerAccessoryView: View {
//    private var todaystamp: String
//    private var namespace: Namespace.ID
//    private let openTodayPlanner: () -> Void
//    
//    init(
//        todaystamp: String,
//        namespace: Namespace.ID,
//        openTodayPlanner: @escaping () -> Void
//    ) {
//        self.namespace = namespace
//        self.todaystamp = todaystamp
//        self.openTodayPlanner = openTodayPlanner
//
//        _planners = Query(
//            filter: #Predicate<Planner> {
//                $0.datestamp == todaystamp
//            }
//        )
//    }
//
//    @Environment(\.tabViewBottomAccessoryPlacement) private var placement
//
//    @Environment(\.modelContext) private var modelContext
//    @Query private var planners: [Planner]
//    
//    @EnvironmentObject private var calendarStore: CalendarStore
//    @EnvironmentObject private var weatherStore: WeatherStore
//
//    let unit: UnitTemperature =
//        Locale.current.measurementSystem == .metric ? .celsius : .fahrenheit
//
//    private var planner: Planner? {
//        planners.first
//    }
//
//    private var weatherData: DayWeather? {
//        weatherStore.getWeather(for: todaystamp, at: planner?.location)
//    }
//
//    private var plannerChipEvents: [EKEvent] {
//        return calendarStore.allDayEventsByDatestamp[
//            todaystamp
//        ] ?? []
//    }
//
//    private var planCountLabel: String {
//
//        let singleDayEvents =
//            calendarStore.singleDayEventsByDatestamp[
//                todaystamp
//            ] ?? []
//
//        let planCount =
//            (planner?.events.filter { !$0.isCompleted }.count ?? 0)
//            + singleDayEvents.count
//
//        if planCount == 0 {
//            if plannerChipEvents.count > 0 {
//                return "No more plans"
//            }
//            return "No plans"
//        }
//
//        return "\(planCount) plan\(planCount == 1 ? "" : "s")"
//    }
//
//    var body: some View {
//        HStack(spacing: 6) {
//            PlannerIcon(datestamp: todaystamp, scale: 1)
//
//            VStack(alignment: .leading, spacing: 0) {
//                Text(todaystamp.date?.weekday ?? "")
//                    .font(.callout)
//                    .matchedTransitionSource(
//                        id: "PLANNER_ACCESSORY",
//                        in: namespace
//                    )
//
//                HStack(alignment: .center, spacing: 6) {
//                    if !plannerChipEvents.isEmpty {
//                        HStack(alignment: .bottom, spacing: 2) {
//                            ForEach(plannerChipEvents, id: \.self) { event in
//                                Image(systemName: event.calendar.iconName)
//                                    .font(.caption)
//                                    .imageScale(.small)
//                                    .foregroundStyle(
//                                        Color(event.calendar.cgColor)
//                                    )
//                            }
//                        }
//
//                        Divider().frame(height: 10)
//                    }
//
//                    Text(planCountLabel)
//                        .font(.caption2)
//                        .foregroundStyle(
//                            Color.secondary
//                        )
//                }
//            }
//            .lineLimit(1)
//
//            Spacer()
//
//            HStack(alignment: .center) {
//                if placement != .inline && weatherData != nil {
//                    VStack(alignment: .trailing, spacing: 0) {
//                        Text(weatherData?.condition.description ?? "")
//                            .font(.caption)
//
//                        HStack(alignment: .center, spacing: 4) {
//                            Text(weatherData?.highTempString(in: unit) ?? "")
//                                .font(.caption2)
//
//                            Divider().frame(height: 10)
//
//                            Text(weatherData?.lowTempString(in: unit) ?? "")
//                                .font(.caption2)
//                        }
//                        .foregroundStyle(
//                            Color.secondary
//                        )
//                    }
//                }
//
//                Image(systemName: weatherData?.symbolName ?? "")
//                    .imageScale(.medium)
//                    .symbolRenderingMode(.multicolor)
//            }
//            .frame(maxHeight: .infinity)
//        }
//        .padding(.horizontal, 16)
//        .contentShape(Rectangle())
//        .onTapGesture(perform: openTodayPlanner)
//        .task {
//            modelContext.ensurePlanner(
//                planners: planners,
//                datestamp: todaystamp
//            )
//        }
//    }
//}
