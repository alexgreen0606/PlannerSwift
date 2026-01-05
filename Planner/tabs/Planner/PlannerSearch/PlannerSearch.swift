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

struct PlannerCoverContext: Identifiable {
    var datestamp: String
    var namespace: Namespace.ID

    var id: String {
        "\(datestamp)-\(namespace)"
    }
}

enum PlannerRoute: Hashable {
    case settings
}

struct PlannerSearchView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var calendarSettingsList: [CalendarSettings]
    @State private var calendarSettings: CalendarSettings?

    @EnvironmentObject var navigationManager: NavigationManager
    @EnvironmentObject var calendarEventStore: CalendarStore
    @EnvironmentObject var todaystampWatcher: TodaystampWatcher
    @ObservedObject var weatherStore = WeatherStore.shared

    @StateObject private var plannerManager = ListManager()

    @State private var plannerCoverContext: PlannerCoverContext?
    @Namespace private var calendarAnimation
    @Namespace private var thisWeekAnimation
    @Namespace private var upcomingAnimation

    @State private var searchText: String = ""
    @State private var isCalendarPickerOpen = false
    @State private var selectedCalendarDate: Date = Date()

    private var thisWeekDatestamps: [String] {
        let region = Region.local
        let today = DateInRegion(Date(), region: region)

        return (0..<7).map {
            today
                .dateByAdding($0, .day)
                .toFormat("yyyy-MM-dd")
        }.sorted()
    }

    private var upcomingEventMap: [String: [String]] {
        let today = todaystampWatcher.todaystamp
        let todayDate = today.toDate("yyyy-MM-dd", region: .local)
        let oneYearOut = todayDate?.dateByAdding(3, .year)

        // All upcoming datestamps.
        let eventDatestamps = Set(
            calendarEventStore.allDayEventsByDatestamp.keys
        ).union(
            calendarEventStore.singleDayEventsByDatestamp.keys
        )

        // Filter to show all future dates.
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

        // Group by year.
        let grouped = Dictionary(grouping: filtered, by: { $0.year })

        // Sort datestamps within each year.
        return grouped.mapValues { values in
            values
                .map { $0.datestamp }
                .sorted()
        }
    }

    private var sortedUpcomingYears: [String] {
        Array(upcomingEventMap.keys).sorted()
    }

    var body: some View {
        NavigationStack(path: $navigationManager.plannerPath) {
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
                            ForEach(thisWeekDatestamps, id: \.self) {
                                datestamp in
                                PlannerCardVerticalView(
                                    datestamp: datestamp,
                                    iconMap: calendarSettings?.iconMap ?? [:]
                                ) {
                                    plannerCoverContext = PlannerCoverContext(
                                        datestamp: datestamp,
                                        namespace: thisWeekAnimation
                                    )
                                }
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

                ForEach(sortedUpcomingYears, id: \.self) { year in
                    Section {
                        ForEach(upcomingEventMap[year] ?? [], id: \.self) {
                            datestamp in
                            PlannerCardView(
                                datestamp: datestamp,
                                iconMap: calendarSettings?.iconMap ?? [:]
                            ) {
                                plannerCoverContext = PlannerCoverContext(
                                    datestamp: datestamp,
                                    namespace: upcomingAnimation
                                )
                            }
                            .matchedTransitionSource(
                                id: datestamp,
                                in: upcomingAnimation
                            )
                            .overlay {
                                if year == sortedUpcomingYears.first!
                                    && datestamp == upcomingEventMap[year]!
                                        .first!
                                {
                                    HStack(alignment: .top) {
                                        Text("Coming up")
                                            .font(.headline)
                                            .foregroundStyle(
                                                Color(uiColor: .secondaryLabel)
                                            )
                                            .offset(y: -48)
                                    }
                                    .frame(
                                        maxWidth: .infinity,
                                        alignment: .leading
                                    )
                                    .frame(
                                        maxHeight: .infinity,
                                        alignment: .top
                                    )
                                }
                            }
                        }
                    } header: {
                        upcomingYearHeader(year)
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
                                        namespace: calendarAnimation
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
                    Button {
                        navigationManager.plannerPath.append(
                            PlannerRoute.settings
                        )
                    } label: {
                        Label {
                            Text("Settings")
                        } icon: {
                            Image(
                                systemName: "gear"
                            )
                        }
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add", systemImage: "plus") {
                        // TODO: open a modal for a new event
                    }
                }
            }
            .navigationDestination(for: PlannerRoute.self) { route in
                switch route {
                case .settings:
                    SettingsView()
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
                        sourceID: context.namespace == calendarAnimation
                            ? "CALENDAR" : context.datestamp,
                        in: context.namespace
                    )
                )
            }
            .task {
                calendarSettings = modelContext.ensureCalendarSettings(
                    settings: calendarSettingsList
                )
                
                calendarEventStore.requestAccessAndLoadIfNeeded(
                    hiddenCalendarIds: calendarSettings?.hiddenCalendarIds ?? []
                )
            }
            .refreshable {
                calendarEventStore.refresh(
                    hiddenCalendarIds: calendarSettings?.hiddenCalendarIds ?? []
                )
                Task {
                    await weatherStore.loadWeather()
                }
            }
        }
        .searchable(
            text: $searchText,
            prompt: "Search calendar events..."
        )
    }

    private func upcomingYearHeader(_ year: String) -> some View {
        Text(year)
            .font(.system(size: 22, weight: .heavy, design: .rounded))
            .foregroundColor(.secondary).frame(
                maxWidth: .infinity,
                alignment: .trailing
            )
    }

}
