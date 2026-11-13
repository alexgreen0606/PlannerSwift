//
//  PlannerContentsList.swift
//  Planner
//
//  Created by Alex Green on 3/11/26.
//

import EventKit
import SwiftData
import SwiftDate
import SwiftUI
import WeatherKit

struct PlannerContentsListView: View {
    @Binding var showLocationSheet: Bool
    @Binding var eventSheetContext: PlannerEventSheetContext?
    let planner: Planner
    let startOfDay: DateInRegion
    let plannerLocation: Location?
    let sortedPlannerEvents: [PlannerEvent]
    let sortedPendingPlannerEvents: [PlannerEvent]
    let sortedCompletePlannerEvents: [PlannerEvent]
    let sortedEventChips: [PlannerEvent]
    let sortedBirthdayChips: [PlannerEvent]
    let showCompleted: Bool
    let scrollProxy: ScrollViewProxy
    let settings: Settings
    let namespace: Namespace.ID
    let createEvent: (Int) -> Void
    let openEvent: (PlannerEvent) -> Void

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @Environment(\.showToast) private var showToast
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var calendarService: CalendarService
    @EnvironmentObject private var todayService: TodayService
    @EnvironmentObject private var plannerEngine: ListEngine<PlannerEvent>
    @EnvironmentObject private var plannerCoverStore: PlannerCoverStore

    // MARK: - Body

    var body: some View {
        SortableTextfieldListView(
            sortedItems: sortedPlannerEvents,
            itemsLabel: "Plans",
            floatingInfo: chipSpread,
            createItem: createEvent,
            moveItem: moveUncheckedEvent,
            deleteItem: deleteEvent,
            onCommitItem: handleEventChange,
            onAdornmentClick: openEvent,
            sortedPendingItems: sortedPendingPlannerEvents,
            sortedCompletedItems: sortedCompletePlannerEvents,
            showCompleted: showCompleted,
            tint: { _ in accentColor.swiftUiColor },
            leftAdornment: { _ in EmptyView() },
            rightAdornment: timeAdornment,
            bottomAdornment: bottomAdornment,
            scrollProxy: scrollProxy,
            namespace: namespace,
            settings: settings
        )
    }

    // MARK: - View Builders

    private var chipSpread: some View {
        PlannerChipSpreadView(
            showLocationSheet: $showLocationSheet,
            planner: planner,
            startOfDay: startOfDay,
            plannerLocation: plannerLocation,
            sortedEventChips: sortedEventChips,
            sortedBirthdayChips: sortedBirthdayChips,
            settings: settings,
            namespace: namespace,
            handleEventClick: { event in
                if plannerEngine.isSelectMode {
                    plannerEngine.toggleItem(event)
                    return
                }

                openEvent(event)
            }
        )
    }

    private func timeAdornment(event: PlannerEvent) -> some View {
        PlannerEventTimeAdornmentView(
            plannerEvent: event,
            plannerDatestamp: planner.datestamp,
            plannerRegion: startOfDay.region
        )
    }

    private func bottomAdornment(event: PlannerEvent) -> some View {
        return PlannerEventBottomAdornmentView(
            plannerEvent: event,
            planner: planner,
            settings: settings
        )
    }

    // MARK: - Functions

    private func moveUncheckedEvent(from: Int, to: Int) {
        modelContext.movePlannerEvent(
            initialIndex: from,
            targetIndex: to,
            sortedPendingPlannerEvents: sortedPendingPlannerEvents,
            sortedPlannerEvents: sortedPlannerEvents,
            startOfDay: startOfDay
        )
    }

    private func deleteEvent(_ event: PlannerEvent) {
        modelContext.deletePlannerEvent(
            event,
            ekEventStore: calendarService.ekEventStore
        )
    }

    private func handleEventChange(event: PlannerEvent) {
        modelContext.handlePlannerEventChange(
            event,
            in: planner,
            startOfDay: startOfDay,
            plannerLocation: plannerLocation,
            todaystamp: todayService.todaystamp,
            ekEventStore: calendarService.ekEventStore,
            showToast: showToast,
            todayService: todayService,
            plannerCoverStore: plannerCoverStore,
            settings: settings
        )
    }
}
