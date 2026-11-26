//
//  PlannerListPreviewContext.swift
//  Planner
//
//  Created by Alex Green on 11/26/26.
//

import EventKit
import SwiftUI

/// Selects which of a planner's items are shown in its list preview.
///
/// Slots are allocated by priority:
/// Trip → Birthdays → Chips → Calendar Events → Timed Unique → Untimed Unique → Timed Routine → Untimed Routine.
///
/// The selected list items are then displayed with all timed items first (sorted by time),
/// followed by all untimed items (sorted by sortDate).
struct PlannerListPreviewContext {
    let tripLabel: String?
    let birthdayItems: [PlannerBirthdayItem]
    let chipItems: [PlannerItem]
    /// Timed items sorted by time, followed by untimed items sorted by sortDate.
    let listItems: [PlannerItem]
    let remainingItemCount: Int
    let hasItems: Bool

    init(
        planner: Planner,
        activeQuery: PlannerSearchQuery?,
        items: PlannerPreviewItems,
        maxPreviewSlots: Int = 5
    ) {
        let datestamp = planner.datestamp

        // MARK: Trip

        let tripLabel: String? = {
            guard let trip = planner.trip else {
                return nil
            }

            if let activeQuery, trip.searchQueryScore(activeQuery) == nil {
                return nil
            }

            return trip.title
        }()

        // MARK: Filter Birthdays and Chips

        func matchesQuery(_ ekEvent: EKEvent) -> Bool {
            guard let activeQuery else { return true }
            return ekEvent.searchQueryScore(activeQuery, in: datestamp) != nil
        }

        let filteredBirthdays = items.sortedBirthdayItems.filter {
            matchesQuery($0.ekEvent)
        }

        let filteredChips = items.sortedChipItems.filter {
            guard let ekEvent = $0.ekEvent else { return false }
            return matchesQuery(ekEvent)
        }

        // MARK: Filter Calendar Events

        let calendarEvents = items.sortedEkEventItems.filter { item in
            guard let ekEvent = item.ekEvent else { return false }

            // Note: Searches include completed events.
            guard let activeQuery else {
                return !item.isCompleted
            }

            return ekEvent.searchQueryScore(activeQuery, in: datestamp) != nil
        }

        // MARK: Filter and Bucket Planner Events

        var timedUniqueEvents: [PlannerItem] = []
        var untimedUniqueEvents: [PlannerItem] = []
        var timedRoutineRecords: [PlannerItem] = []
        var untimedRoutineRecords: [PlannerItem] = []

        for event in items.sortedPlannerEvents {
            if let activeQuery {
                guard
                    event.searchQueryScore(activeQuery, in: datestamp) != nil
                else { continue }
            } else {
                guard !event.isCompleted else { continue }
            }

            let item = PlannerItem(plannerEvent: event)
            let isTimed = event.time != nil
            let isRoutineRecord = event.routineEventRecordContext != nil

            switch (isTimed, isRoutineRecord) {
            case (true, false):
                timedUniqueEvents.append(item)
            case (false, false):
                untimedUniqueEvents.append(item)
            case (true, true):
                timedRoutineRecords.append(item)
            case (false, true):
                untimedRoutineRecords.append(item)
            }
        }

        // MARK: Allocate Preview Slots

        let tripSlotSize = tripLabel == nil ? 0 : 1

        var remainingSlots = max(0, maxPreviewSlots - tripSlotSize)

        func take<T>(_ elements: [T]) -> [T] {
            guard remainingSlots > 0, !elements.isEmpty else {
                return []
            }

            let slice = Array(elements.prefix(remainingSlots))
            remainingSlots -= slice.count

            return slice
        }

        let birthdays = take(filteredBirthdays)
        let chips = take(filteredChips)

        let selectedListItems =
            take(calendarEvents)
            + take(timedUniqueEvents)
            + take(untimedUniqueEvents)
            + take(timedRoutineRecords)
            + take(untimedRoutineRecords)

        // MARK: Sort List Preview

        var timedItems: [(item: PlannerItem, time: Date)] = []
        var untimedItems: [PlannerItem] = []

        for item in selectedListItems {
            if let time = item.time {
                timedItems.append((item, time))
            } else {
                untimedItems.append(item)
            }
        }

        timedItems.sort {
            $0.time == $1.time
                ? $0.item.sortDate < $1.item.sortDate
                : $0.time < $1.time
        }
        untimedItems.sort { $0.sortDate < $1.sortDate }

        // MARK: Count Items

        let totalItemCount =
            tripSlotSize
            + filteredBirthdays.count
            + filteredChips.count
            + calendarEvents.count
            + timedUniqueEvents.count
            + untimedUniqueEvents.count
            + timedRoutineRecords.count
            + untimedRoutineRecords.count

        let previewItemCount =
            tripSlotSize
            + birthdays.count
            + chips.count
            + selectedListItems.count

        self.tripLabel = tripLabel
        self.birthdayItems = birthdays
        self.chipItems = chips
        self.listItems = timedItems.map(\.item) + untimedItems
        self.remainingItemCount = totalItemCount - previewItemCount
        self.hasItems = totalItemCount > 0
    }

    // MARK: - Computed Properties

    var remainingPlansLabel: LocalizedStringKey {
        guard remainingItemCount > 0 else {
            return hasItems ? "No more plans" : "No plans"
        }

        return "^[\(remainingItemCount) more plan](inflect: true)"
    }
}
