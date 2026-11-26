//
//  ModelContext+plannerItems.swift
//  Planner
//
//  Created by Alex Green on 11/24/26.
//

import EventKit
import SwiftData
import SwiftDate
import SwiftUI

extension ModelContext {
    // MARK: - CREATE

    @MainActor
    func createPlannerItem(
        at index: Int,
        in sortedItems: [PlannerItem],
        startOfDay: DateInRegion
    ) -> /// The ID of the new item.
        PlannerItemID
    {
        let sortDate = generatePlannerItemSortDate(
            at: index,
            in: sortedItems,
            startOfDay: startOfDay,
            modelContext: self
        )

        let newEvent = PlannerEvent(
            datestamp: startOfDay.datestamp,
            sortDate: sortDate
        )

        insert(newEvent)

        safeSave("ModelContext+plannerItems createPlannerItem")

        return .plannerEvent(newEvent.stableId)
    }

    /// Creates an `EkEventPlannerState` for every calendar event in the planner that doesn't have one yet.
    ///
    /// A calendar event without a state is assumed to be newly created, so it's placed at the top of the
    /// first planner to load it. When several new events are placed at once, they're kept in chronological order.
    @MainActor
    func placeNewEkEventItems(
        /// All of the planner's list items, sorted by sortDate. New EKEvents are sorted by startDate.
        in sortedItems: [PlannerItem],
        startOfDay: DateInRegion
    ) {
        var existingItems: [PlannerItem] = []
        var newEkEvents: [EKEvent] = []

        // Note: The item's state may be stale (e.g. inserted by another loader of this planner
        // but not yet picked up by its query). Existing states keep their position.
        for item in sortedItems {
            guard case .ekEvent(let ekEvent, nil) = item.source,
                getEkEventPlannerState(for: ekEvent) == nil
            else {
                existingItems.append(item)
                continue
            }

            newEkEvents.append(ekEvent)
        }

        guard !newEkEvents.isEmpty else { return }

        // Place the events together at the top, in chronological order.
        let sortDates = generatePlannerItemSortDates(
            count: newEkEvents.count,
            at: 0,
            in: existingItems,
            startOfDay: startOfDay,
            modelContext: self
        )

        for (ekEvent, sortDate) in zip(newEkEvents, sortDates) {
            _ = ensureEkEventPlannerState(for: ekEvent, sortDate: sortDate)
        }

        safeSave("ModelContext+plannerItems placeNewEkEventItems")
    }

    // MARK: - UPDATE

    @MainActor
    func movePlannerItem(
        /// The initial index within sortedPendingItems.
        initialIndex: Int,
        /// The target index within sortedItems.
        targetIndex: Int,
        sortedPendingItems: [PlannerItem],
        sortedItems: [PlannerItem],
        startOfDay: DateInRegion
    ) {
        let movedItem = sortedPendingItems[initialIndex]

        let sortDate = generatePlannerItemSortDate(
            at: targetIndex,
            in: sortedItems,
            startOfDay: startOfDay,
            modelContext: self
        )

        setSortDate(sortDate, for: movedItem)

        safeSave("ModelContext+plannerItems movePlannerItem")
    }

    /// Persists the edits made to an item by the list.
    @MainActor
    func handlePlannerItemChange(
        _ item: PlannerItem,
        in planner: Planner,
        startOfDay: DateInRegion,
        plannerLocation: Location?,
        todaystamp: String,
        ekEventStore: EKEventStore,
        showToast: (Toast) -> Void,
        todayService: TodayService,
        plannerCoverStore: PlannerCoverStore,
        settings: Settings
    ) {
        switch item.source {
        case .plannerEvent(let plannerEvent):
            handlePlannerEventChange(
                plannerEvent,
                in: planner,
                startOfDay: startOfDay,
                plannerLocation: plannerLocation,
                todaystamp: todaystamp,
                ekEventStore: ekEventStore,
                showToast: showToast,
                todayService: todayService,
                plannerCoverStore: plannerCoverStore,
                settings: settings
            )

        case .ekEvent(let ekEvent, _):
            // The list has already written the draft to the EKEvent. Save it to the calendar.
            guard ekEvent.hasChanges,
                ekEventStore.attemptUpdateEvent(ekEvent)
            else { return }
        }
    }

    @MainActor
    func shiftPlannerItems(
        _ items: [PlannerItem],
        days: DateComponents,
        sourceDatestamp: String,
        destinationDatestamp: String,
        todayService: TodayService,
        ekEventStore: EKEventStore,
        settings: Settings
    ) -> /// The number of items that were shifted.
        Int
    {
        // Assemble the items in reverse-chronological ordering so they
        // are inserted correctly.
        let reverseSortedItems = items.sorted {
            $0.sortDate > $1.sortDate
        }

        var successCount = 0

        for item in reverseSortedItems {
            if shiftPlannerItem(
                item,
                days: days,
                sourceDatestamp: sourceDatestamp,
                destinationDatestamp: destinationDatestamp,
                todayStartOfDay: todayService.todayStartOfDay,
                ekEventStore: ekEventStore,
                settings: settings
            ) {
                successCount += 1
            }
        }

        safeSave("ModelContext+plannerItems shiftPlannerItems")

        return successCount
    }

    @MainActor
    func shiftPlannerItem(
        _ item: PlannerItem,
        days: DateComponents,
        sourceDatestamp: String,
        destinationDatestamp: String,
        todayStartOfDay: DateInRegion,
        ekEventStore: EKEventStore,
        settings: Settings
    ) -> Bool {
        switch item.source {
        case .plannerEvent(let plannerEvent):
            if let time = plannerEvent.time {
                plannerEvent.time = time + days
            }

            plannerEvent.datestamp = destinationDatestamp

            // Place the event at the top of its new planner.
            _ = ensureValidPlannerEventPosition(
                for: plannerEvent,
                sourceDatestamp: sourceDatestamp,
                todayStartOfDay: todayStartOfDay,
                settings: settings
            )

            // If the datestamp didn't change, this means the event was force-pushed back
            // to the planner due to a flag (the planner is today's planner).
            return plannerEvent.datestamp != sourceDatestamp

        case .ekEvent(let ekEvent, let state):
            guard ekEvent.calendar.allowsContentModifications else {
                return false
            }

            // Shift the start and end dates and save.
            ekEvent.startDate = ekEvent.startDate + days
            ekEvent.endDate = ekEvent.endDate + days

            guard ekEventStore.attemptUpdateEvent(ekEvent) else {
                return false
            }

            // Drop the old position so the event is placed at the top of its new planner.
            deleteEkEventPlannerState(for: ekEvent, existing: state)

            return true
        }
    }

    @MainActor
    func setSortDate(_ sortDate: Date, for item: PlannerItem) {
        switch item.source {
        case .plannerEvent(let plannerEvent):
            plannerEvent.sortDate = sortDate

        case .ekEvent(let ekEvent, let state):
            ensureEkEventPlannerState(
                for: ekEvent,
                existing: state,
                sortDate: sortDate
            ).sortDate = sortDate
        }
    }

    // MARK: - DELETE

    @MainActor
    func deletePlannerItem(
        _ item: PlannerItem,
        /// Deletes calendar events if defined, otherwise they are preserved.
        ekEventStore: EKEventStore? = nil,
        skipSave: Bool = false
    ) {
        switch item.source {
        case .plannerEvent(let plannerEvent):
            delete(plannerEvent)

        case .ekEvent(let ekEvent, let state):
            guard let ekEventStore else { return }

            if !ekEventStore.attemptDeleteEvent(ekEvent) {
                return
            }

            deleteEkEventPlannerState(for: ekEvent, existing: state)
        }

        guard !skipSave else { return }

        safeSave("ModelContext+plannerItems deletePlannerItem")
    }

    @MainActor
    func deletePlannerItems(
        _ items: [PlannerItem],
        /// Deletes calendar events if defined, otherwise they are preserved.
        ekEventStore: EKEventStore? = nil
    ) {
        for item in items {
            deletePlannerItem(
                item,
                ekEventStore: ekEventStore,
                skipSave: true
            )
        }

        safeSave("ModelContext+plannerItems deletePlannerItems")
    }
}
