//
//  PlannerSelector.swift
//  Planner
//
//  Created by Alex Green on 12/16/25.
//

import EventKit
import SwiftDate
import SwiftUI

enum PlannerConfig: Identifiable {
    case calendar(String)
    case card(String)

    var id: String {
        switch self {
        case .calendar: return "CALENDAR"
        case .card(let datestamp): return datestamp
        }
    }
}

// TODO: use a list instead of lazy vstack to prevent choppy scrolling

struct PlannerSelectView: View {
    @EnvironmentObject var todaystampManager: TodaystampManager

    @State private var plannerConfig: PlannerConfig?
    @State private var isCalendarPickerOpen = false
    @State var navigationManager = NavigationManager.shared
    @State var calendarEventStore = CalendarEventStore.shared

    @State private var calendarEventEditConfig: CalendarEventEditConfig?

    @Namespace private var calendarEventSheetNamespace
    @Namespace private var plannerAnimation

    let plannerManager = ListManager()

    @AppStorage("themeColor") private var themeColor: ThemeColorOption = .blue

    var nextWeekDatestamps: [String] {
        let requiredDates: Set<String> = Set(
            (1...6).compactMap { offset in
                DateInRegion(region: .current)
                    .dateByAdding(offset, .day)
                    .toFormat("yyyy-MM-dd", locale: Locale.current)
            }
        )
        return Array(requiredDates).sorted()
    }

    var nextYearDatestamps: [String] {
        let today = todaystampManager.todaystamp
        let todayDate = today.toDate("yyyy-MM-dd", region: .current)
        let nextWeekDate = todayDate?.dateByAdding(7, .day)
        let oneYearOut = todayDate?.dateByAdding(1, .year)

        // All upcoming dates.
        let eventDates = Set(
            calendarEventStore.allDayEventsByDatestamp.keys
        ).union(
            calendarEventStore.singleDayEventsByDatestamp.keys
        )

        // Filter out events further than a year away.
        return Array(eventDates)
            .filter { datestamp in
                guard
                    let date = datestamp.toDate("yyyy-MM-dd", region: .current),
                    let nextWeekDate,
                    let oneYearOut
                else { return false }

                return date >= nextWeekDate && date < oneYearOut
            }
            .sorted()
    }

    var body: some View {
        List {
            
            Section {
                DatePicker(
                    "Open a planner",
                    selection: $navigationManager
                        .selectedPlannerDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .listRowBackground(Color.clear)
                .onChange(of: navigationManager.selectedPlannerDate) {
                    _,
                    targetPlannerDate in
                    plannerConfig = .calendar(targetPlannerDate.datestamp)
                }
                .matchedTransitionSource(
                    id: "CALENDAR",
                    in: plannerAnimation
                )
            }
            .listSectionSeparator(.hidden)

            Section {
                ForEach(nextWeekDatestamps, id: \.self) { datestamp in
                    let allDayEvents =
                        calendarEventStore.allDayEventsByDatestamp[
                            datestamp
                        ]
                        ?? []
                    let singleDayEvents =
                        calendarEventStore.singleDayEventsByDatestamp[
                            datestamp
                        ]
                        ?? []

                    PlannerCard(
                        datestamp: datestamp,
                        allDayEvents: allDayEvents,
                        singleDayEvents: singleDayEvents,
                        chipAnimation: calendarEventSheetNamespace,
                        openCalendarEvent: openCalendarEventModal
                    ) {
                        plannerConfig = .card(datestamp)
                    }
                    .matchedTransitionSource(
                        id: datestamp,
                        in: plannerAnimation
                    )
                }
            } header: {
                listSectionHeader("This week")
            }
            .listSectionSeparator(.hidden)

            Section {
                ForEach(nextYearDatestamps, id: \.self) { datestamp in
                    let allDayEvents =
                        calendarEventStore.allDayEventsByDatestamp[
                            datestamp
                        ]
                        ?? []
                    let singleDayEvents =
                        calendarEventStore.singleDayEventsByDatestamp[
                            datestamp
                        ]
                        ?? []

                    PlannerCard(
                        datestamp: datestamp,
                        allDayEvents: allDayEvents,
                        singleDayEvents: singleDayEvents,
                        chipAnimation: calendarEventSheetNamespace,
                        openCalendarEvent: openCalendarEventModal
                    ) {
                        plannerConfig = .card(datestamp)
                    }
                    .matchedTransitionSource(
                        id: datestamp,
                        in: plannerAnimation
                    )
                }
            } header: {
                listSectionHeader("This year")
            }
        }
        .listStyle(.plain)
        .navigationTitle("Planner")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Menu {
                        ForEach(ThemeColorOption.allCases, id: \.self) {
                            option in
                            Button {
                                themeColor = option
                            } label: {
                                Label {
                                    Text(option.label)
                                } icon: {
                                    Image(
                                        systemName:
                                            themeColor == option
                                            ? "circle.fill"
                                            : "circle"
                                    )
                                }
                                .tint(option.swiftUIColor)
                            }
                        }
                    } label: {
                        Label("Theme Color", systemImage: "paintpalette.fill")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                }
            }
        }
        .fullScreenCover(item: $plannerConfig) { planner in
            switch planner {
            case .calendar(let datestamp):
                NavigationStack {
                    PlannerView(datestamp: datestamp) {
                        plannerConfig = nil
                    }
                }
                .environmentObject(plannerManager)
                .navigationTransition(
                    .zoom(sourceID: "CALENDAR", in: plannerAnimation)
                )

            case .card(let datestamp):
                NavigationStack {
                    PlannerView(datestamp: datestamp) {
                        plannerConfig = nil
                    }
                }
                .environmentObject(plannerManager)
                .navigationTransition(
                    .zoom(
                        sourceID: datestamp,
                        in: plannerAnimation
                    )
                )
            }
        }
        .sheet(item: $calendarEventEditConfig) { destination in
            switch destination {
            case .edit(let event):
                EditCalendarEventView(
                    event: event,
                    eventStore: calendarEventStore.ekEventStore
                ) { action, updatedEvent in
                    calendarEventStore.refresh()
                    calendarEventEditConfig = nil
                }
                .tint(themeColor.swiftUIColor)
                .ignoresSafeArea()
                .navigationTransition(
                    .zoom(
                        sourceID: String(describing: event.eventIdentifier),
                        in: calendarEventSheetNamespace
                    )
                )

            case .view(let event):
                ViewCalendarEventView(event: event)
                    .tint(themeColor.swiftUIColor)
                    .presentationDetents([.height(340)])
                    .ignoresSafeArea()
                    .navigationTransition(
                        .zoom(
                            sourceID: String(describing: event.eventIdentifier),
                            in: calendarEventSheetNamespace
                        )
                    )
            }
        }
    }

    private func openCalendarEventModal(for event: EKEvent) {
        if event.calendar.allowsContentModifications {
            calendarEventEditConfig = .edit(event)
        } else {
            calendarEventEditConfig = .view(event)
        }
    }

    @ViewBuilder
    func listSectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 22, weight: .heavy, design: .rounded))
    }

}
