//
//  PlannerContentsList.swift
//  Planner
//
//  Created by Alex Green on 11/22/26.
//

import EventKit
import SwiftData
import SwiftDate
import SwiftUI

struct PlannerContentsListView: View {
    @Binding var showLocationSheet: Bool
    let planner: Planner
    let startOfDay: DateInRegion
    let plannerLocation: Location?
    let sortedListItems: [PlannerItem]
    let sortedPendingListItems: [PlannerItem]
    let sortedCompleteListItems: [PlannerItem]
    let sortedChipItems: [PlannerItem]
    let sortedBirthdayItems: [PlannerBirthdayItem]
    let showCompleted: Bool
    let scrollProxy: ScrollViewProxy
    let settings: Settings
    let namespace: Namespace.ID
    let createItem: (Int) -> Void
    let openItem: (PlannerItem) -> Void

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @Environment(\.showToast) private var showToast
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var calendarService: CalendarService
    @EnvironmentObject private var todayService: TodayService
    @EnvironmentObject private var plannerEngine: ListEngine<PlannerItem>
    @EnvironmentObject private var plannerCoverStore: PlannerCoverStore

    // MARK: - Body

    var body: some View {
        SortableTextfieldListView(
            sortedItems: sortedListItems,
            itemsLabel: "Plans",
            floatingInfo: chipSpread,
            createItem: createItem,
            moveItem: moveUncheckedItem,
            deleteItem: deleteItem,
            onCommitItem: handleItemChange,
            onAdornmentClick: openItem,
            sortedPendingItems: sortedPendingListItems,
            sortedCompletedItems: sortedCompleteListItems,
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
            sortedChipItems: sortedChipItems,
            sortedBirthdayItems: sortedBirthdayItems,
            settings: settings,
            namespace: namespace,
            handleItemClick: { item in
                if plannerEngine.isSelectMode {
                    plannerEngine.toggleItem(item)
                    return
                }

                openItem(item)
            }
        )
    }

    private func timeAdornment(item: PlannerItem) -> some View {
        PlannerItemTimeAdornmentView(
            item: item,
            plannerDatestamp: planner.datestamp,
            plannerRegion: startOfDay.region
        )
    }

    private func bottomAdornment(item: PlannerItem) -> some View {
        PlannerItemBottomAdornmentView(
            item: item,
            planner: planner,
            settings: settings
        )
    }

    // MARK: - Functions

    private func moveUncheckedItem(from: Int, to: Int) {
        modelContext.movePlannerItem(
            initialIndex: from,
            targetIndex: to,
            sortedPendingItems: sortedPendingListItems,
            sortedItems: sortedListItems,
            startOfDay: startOfDay
        )
    }

    private func deleteItem(_ item: PlannerItem) {
        modelContext.deletePlannerItem(
            item,
            ekEventStore: calendarService.ekEventStore
        )
    }

    private func handleItemChange(item: PlannerItem) {
        modelContext.handlePlannerItemChange(
            item,
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
