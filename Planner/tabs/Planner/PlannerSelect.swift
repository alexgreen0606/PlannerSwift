//
//  PlannerSelector.swift
//  Planner
//
//  Created by Alex Green on 12/16/25.
//

import EventKit
import SwiftData
import SwiftDate
import SwiftUI

enum PlannerCoverConfig: Identifiable {
    case calendar(String)
    case card(String)
    case cardVertical(String)

    var id: String {
        switch self {
        case .calendar: return "CALENDAR"
        case .card(let datestamp): return "\(datestamp)_PlannerCard"
        case .cardVertical(let datestamp):
            return "\(datestamp)_PlannerCardVertical"
        }
    }

    var datestamp: String {
        switch self {
        case .card(let datestamp),
            .calendar(let datestamp),
            .cardVertical(let datestamp):
            return datestamp
        }
    }
}

enum CalendarEventSheetConfig: Identifiable {
    case edit(EKEvent, String)
    case view(EKEvent, String)

    var id: String {
        switch self {
        case .edit(let event, let key), .view(let event, let key):
            "\(String(describing: event.eventIdentifier))_\(key)"
        }
    }
}

struct PlannerSelectView: View {
    @State private var plannerCoverConfig: PlannerCoverConfig?
    @State private var calendarEventSheetConfig: CalendarEventSheetConfig?
    @Namespace private var calendarEventSheetNamespace
    @Namespace private var plannerAnimation

    @State private var isCalendarPickerOpen = false

    @State var navigationManager = NavigationManager.shared
    @State var calendarEventStore = CalendarEventStore.shared
    @EnvironmentObject var todaystampManager: TodaystampManager

    let plannerManager = ListManager()

    @AppStorage("themeColor") private var themeColor: ThemeColorOption = .blue

    var eventsByYear: [String: [String]] {
        let today = todaystampManager.todaystamp
        let todayDate = today.toDate("yyyy-MM-dd", region: .current)
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
                let date = datestamp.toDate("yyyy-MM-dd", region: .current),
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
        let region = Region.current
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
                                chipAnimation:
                                    calendarEventSheetNamespace,
                                openCalendarEventSheet:
                                    openCalendarEventSheet
                            ) {
                                plannerCoverConfig = .cardVertical(datestamp)
                            }
                            .matchedTransitionSource(
                                id: "\(datestamp)_PlannerCardVertical",
                                in: plannerAnimation
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
                                chipAnimation: calendarEventSheetNamespace,
                                openCalendarEventSheet: openCalendarEventSheet
                            ) {
                                plannerCoverConfig = .card(datestamp)
                            }
                            .matchedTransitionSource(
                                id: "\(datestamp)_PlannerCard",
                                in: plannerAnimation
                            )
                            .overlay {
                                if year == sortedYears.first! && datestamp == eventsByYear[year]!.first! {
                                    HStack {
                                            Text("Coming up")
                                                .font(.headline)
                                                .foregroundStyle(Color(uiColor: .secondaryLabel))

                                            Spacer()
                                        }
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(.bottom, 166)
                                        .listRowInsets(EdgeInsets())
                                        .listRowSeparator(.hidden)
                                }
                            }
                        }
                    } header: {
                        listSectionHeader(year)
                    }
                }
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
                            selection: $navigationManager
                                .selectedPlannerDate,
                            displayedComponents: .date
                        )
                        .datePickerStyle(.graphical)
                        .listRowBackground(Color.clear)
                        .onChange(of: navigationManager.selectedPlannerDate) {
                            _,
                            targetPlannerDate in
                            plannerCoverConfig = .calendar(
                                targetPlannerDate.datestamp
                            )
                        }
                        .matchedTransitionSource(
                            id: "CALENDAR",
                            in: plannerAnimation
                        )
                    }
                    .frame(width: 340, height: 320)
                    .padding()
                    .presentationCompactAdaptation(.popover)
                }
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
        }
        .fullScreenCover(item: $plannerCoverConfig) { planner in
            NavigationStack {
                PlannerView(datestamp: planner.datestamp) {
                    plannerCoverConfig = nil
                }
            }
            .environmentObject(plannerManager)
            .navigationTransition(
                .zoom(
                    sourceID: planner.id,
                    in: plannerAnimation
                )
            )
        }
        .sheet(item: $calendarEventSheetConfig) { destination in
            switch destination {
            case .edit(let event, _):
                EditCalendarEventView(
                    event: event,
                    eventStore: calendarEventStore.ekEventStore
                ) { action, updatedEvent in
                    calendarEventStore.refresh()
                    calendarEventSheetConfig = nil
                }
                .tint(themeColor.swiftUIColor)
                .ignoresSafeArea()
                .navigationTransition(
                    .zoom(
                        sourceID: destination.id,
                        in: calendarEventSheetNamespace
                    )
                )

            case .view(let event, _):
                ViewCalendarEventView(event: event)
                    .tint(themeColor.swiftUIColor)
                    .presentationDetents([.height(340)])
                    .ignoresSafeArea()
                    .navigationTransition(
                        .zoom(
                            sourceID: destination.id,
                            in: calendarEventSheetNamespace
                        )
                    )
            }
        }
    }

    private func openCalendarEventSheet(for event: EKEvent, from key: String) {
        if event.calendar.allowsContentModifications {
            calendarEventSheetConfig = .edit(event, key)
        } else {
            calendarEventSheetConfig = .view(event, key)
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
