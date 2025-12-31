//
//  PlannerSearch.swift
//  Planner
//
//  Created by Alex Green on 12/16/25.
//

import EventKit
import SwiftData
import SwiftDate
import SwiftUI

struct CalendarEventSheetContext: Identifiable {
    var event: EKEvent
    var namespace: Namespace.ID
    
    var id: String {
        "\(String(describing: event.eventIdentifier))-\(namespace)"
    }
}

struct PlannerCoverContext: Identifiable {
    var datestamp: String
    var namespace: Namespace.ID
    var fromCalendar: Bool?
    
    var id: String {
        "\(datestamp)-\(namespace)"
    }
}

struct PlannerSearchView: View {
    @AppStorage("themeColor") private var themeColor: ThemeColorOption = .blue

    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var calendarEventStore: CalendarEventStore
    @EnvironmentObject var todaystampManager: TodaystampWatcher

    @StateObject private var plannerManager = ListManager()
    
    @State private var calendarEventSheetContext: CalendarEventSheetContext?
    @State private var plannerCoverContext: PlannerCoverContext?

    @Namespace private var thisWeekAnimation
    @Namespace private var comingUpAnimation
    @Namespace private var calendarAnimation

    @State private var isCalendarPickerOpen = false
    @State private var selectedCalendarDate: Date = Date()

    var eventsByYear: [String: [String]] {
        let today = todaystampManager.todaystamp
        let todayDate = today.toDate("yyyy-MM-dd", region: .local)
        let oneYearOut = todayDate?.dateByAdding(3, .year)

        // All upcoming datestamps.
        let eventDatestamps = Set(
            calendarEventStore.allDayEventsByDatestamp.keys
        ).union(
            calendarEventStore.singleDayEventsByDatestamp.keys
        )

        // Filter to next week → one year out
        let filtered = eventDatestamps.compactMap {
            datestamp -> (year: String, datestamp: String)? in
            guard
                let date = datestamp.toDate("yyyy-MM-dd", region: .local),
                let oneYearOut,
                let todayDate,
                date > todayDate,
                date < oneYearOut
            else { return nil }

            let year = String(date.year)
            return (year, datestamp)
        }

        // Group by year
        let grouped = Dictionary(grouping: filtered, by: { $0.year })

        // Sort datestamps within each year
        return grouped.mapValues { values in
            values
                .map { $0.datestamp }
                .sorted()
        }
    }

    var eventDatestamps: [String] {
        let region = Region.local
        let today = DateInRegion(Date(), region: region)

        return (0..<7).map {
            today
                .dateByAdding($0, .day)
                .toFormat("yyyy-MM-dd")
        }.sorted()
    }

    var sortedYears: [String] {
        Array(eventsByYear.keys).sorted()
    }

    var body: some View {
        List {
            Section {
                Text("This week")
                    .padding(.leading, 16)
                    .font(.headline)
                    .foregroundStyle(Color(uiColor: .secondaryLabel))
                    .listRowSeparator(.hidden)
                    .listRowInsets(.bottom, 0)

                ScrollView(.horizontal) {
                    HStack(alignment: .top, spacing: 12) {
                        ForEach(eventDatestamps, id: \.self) {
                            datestamp in
                            PlannerCardVertical(
                                datestamp: datestamp,
                                allDayEvents:
                                    calendarEventStore
                                    .allDayEventsByDatestamp[
                                        datestamp
                                    ] ?? [],
                                singleDayEvents:
                                    calendarEventStore
                                    .singleDayEventsByDatestamp[
                                        datestamp
                                    ] ?? [],
                                animation: thisWeekAnimation,
                                openCalendarEventSheet: { event in
                                    calendarEventSheetContext = CalendarEventSheetContext(
                                        event: event,
                                        namespace: thisWeekAnimation
                                    )
                                }
                            ) {
                                plannerCoverContext = PlannerCoverContext(
                                    datestamp: datestamp,
                                    namespace: thisWeekAnimation
                                )                            }
                            .matchedTransitionSource(
                                id: datestamp,
                                in: thisWeekAnimation
                            )
                        }
                    }
                    .padding(.horizontal, 16)
                }
                .scrollIndicators(.hidden)
                .horizontalEdgeFade(leading: 16, trailing: 16)
                .background(Color.appBackground)
            }
            .listSectionSeparator(.hidden)
            .listRowBackground(Color.appBackground)
            .listRowInsets(.horizontal, 0)

            ForEach(sortedYears, id: \.self) { year in
                Section {
                    ForEach(eventsByYear[year] ?? [], id: \.self) { datestamp in
                        PlannerCard(
                            datestamp: datestamp,
                            allDayEvents:
                                calendarEventStore.allDayEventsByDatestamp[
                                    datestamp
                                ] ?? [],
                            singleDayEvents:
                                calendarEventStore.singleDayEventsByDatestamp[
                                    datestamp
                                ] ?? [],
                            animation: comingUpAnimation,
                            openCalendarEventSheet: { event in
                                calendarEventSheetContext = CalendarEventSheetContext(
                                    event: event,
                                    namespace: comingUpAnimation
                                )
                            }
                        ) {
                            plannerCoverContext = PlannerCoverContext(
                                datestamp: datestamp,
                                namespace: comingUpAnimation
                            )
                        }
                        .matchedTransitionSource(
                            id: datestamp,
                            in: comingUpAnimation
                        )
                        .overlay {
                            if year == sortedYears.first!
                                && datestamp == eventsByYear[year]!.first!
                            {
                                HStack(alignment: .top) {
                                    Text("Coming up")
                                        .font(.headline)
                                        .foregroundStyle(
                                            Color(uiColor: .secondaryLabel)
                                        )
                                        .offset(y: -48)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .frame(maxHeight: .infinity, alignment: .top)
                            }
                        }
                    }
                } header: {
                    listSectionHeader(year)
                }
            }
        }
        .refreshable {
            calendarEventStore.refresh()
        }
        .listStyle(.plain)
        .background(Color.appBackground)
        .navigationTitle("Planner")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Calendar", systemImage: "calendar") {
                    isCalendarPickerOpen = true
                }
                .popover(isPresented: $isCalendarPickerOpen) {
                    VStack {
                        DatePicker(
                            "Open a planner",
                            selection: $selectedCalendarDate,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .listRowBackground(Color.clear)
                        .onChange(of: selectedCalendarDate) {
                            _,
                            targetPlannerDate in
                            isCalendarPickerOpen = false

                            DispatchQueue.main.async {
                                plannerCoverContext = PlannerCoverContext(
                                    datestamp: targetPlannerDate.datestamp,
                                    namespace: calendarAnimation,
                                    fromCalendar: true
                                )
                            }
                        }
                    }
                    .frame(width: 340, height: 320)
                    .padding()
                    .presentationCompactAdaptation(.popover)
                }
                .matchedTransitionSource(
                    id: "CALENDAR",
                    in: calendarAnimation
                )
            }

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

            ToolbarItem(placement: .topBarTrailing) {
                Button("Add", systemImage: "plus") {
                    // TODO: open a modal for a new event
                }
            }
        }
        .fullScreenCover(item: $plannerCoverContext) { context in
            NavigationStack {
                PlannerView(datestamp: context.datestamp) {
                    plannerCoverContext = nil
                }
            }
            .environmentObject(plannerManager)
            .navigationTransition(
                .zoom(
                    sourceID: context.fromCalendar == true ? "CALENDAR" : context.datestamp,
                    in: context.namespace
                )
            )
        }
        .sheet(item: $calendarEventSheetContext) { context in
            switch context.event.calendar.allowsContentModifications {
            case true:
                EditCalendarEventView(
                    event: context.event,
                    eventStore: calendarEventStore.ekEventStore
                ) { action, updatedEvent in
                    calendarEventStore.refresh()
                    calendarEventSheetContext = nil
                }
                .tint(themeColor.swiftUIColor)
                .ignoresSafeArea()
                .navigationTransition(
                    .zoom(
                        sourceID: String(describing: context.event.eventIdentifier),
                        in: context.namespace
                    )
                )

            case false:
                ViewCalendarEventView(event: context.event)
                    .tint(themeColor.swiftUIColor)
                    .presentationDetents([.height(340)])
                    .ignoresSafeArea()
                    .navigationTransition(
                        .zoom(
                            sourceID: String(describing: context.event.eventIdentifier),
                            in: context.namespace
                        )
                    )
            }
        }
    }

    @ViewBuilder
    func listSectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 22, weight: .heavy, design: .rounded))
            .foregroundColor(.secondary).frame(
                maxWidth: .infinity,
                alignment: .trailing
            )
    }

}
