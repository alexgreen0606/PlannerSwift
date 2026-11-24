//
//  StructuredPlannerPreviewContext.swift
//  Planner
//
//  Created by Alex Green on 11/14/26.
//

import EventKit
import SwiftDate
import SwiftUI

struct StructuredPlannerPreviewContext {
    private let planner: Planner
    private let activeQuery: PlannerSearchQuery?

    init(
        planner: Planner,
        activeQuery: PlannerSearchQuery? = nil,
        sortedBirthdayEvents: [PlannerEvent],
        sortedChipItems: [PlannerEvent],
        sortedPlannerEvents: [PlannerEvent],
        maxPreviewSlots: Int = 5
    ) {
        self.planner = planner
        self.activeQuery = activeQuery

        let datestamp = planner.datestamp

        // MARK: Trip

        let tripLabel: String? = {
            guard let trip = planner.trip else {
                return nil
            }

            if let activeQuery,
                trip.searchQueryScore(activeQuery) == nil
            {
                return nil
            }

            return trip.title
        }()

        // MARK: Filter Search Results For Non-List Events

        let filteredBirthdayChips: [PlannerEvent]
        let filteredEventChips: [PlannerEvent]

        if let activeQuery {
            filteredBirthdayChips = sortedBirthdayEvents.filter {
                $0.searchQueryScore(activeQuery, in: datestamp) != nil
            }

            filteredEventChips = sortedChipItems.filter {
                $0.searchQueryScore(activeQuery, in: datestamp) != nil
            }
        } else {
            filteredBirthdayChips = sortedBirthdayEvents
            filteredEventChips = sortedChipItems
        }

        // MARK: Filter Search Results for List Events

        var calendarEvents: [PlannerEvent] = []
        var timedUniqueEvents: [PlannerEvent] = []
        var untimedUniqueEvents: [PlannerEvent] = []
        var timedRoutineRecords: [PlannerEvent] = []
        var untimedRoutineRecords: [PlannerEvent] = []

        calendarEvents.reserveCapacity(sortedPlannerEvents.count)

        var filteredPlannerEventCount = 0

        for event in sortedPlannerEvents {
            if let activeQuery {
                guard
                    event.searchQueryScore(activeQuery, in: datestamp) != nil
                else {
                    continue
                }
            } else {
                guard !event.isCompleted else {
                    continue
                }
            }

            filteredPlannerEventCount += 1

            guard event.eKEventContext == nil else {
                calendarEvents.append(event)
                continue
            }

            let isTimed = event.time != nil
            let isRoutineRecord = event.routineEventRecordContext != nil

            switch (isTimed, isRoutineRecord) {
            case (true, false):
                timedUniqueEvents.append(event)
            case (false, false):
                untimedUniqueEvents.append(event)
            case (true, true):
                timedRoutineRecords.append(event)
            case (false, true):
                untimedRoutineRecords.append(event)
            }
        }

        // MARK: Allocate Preview Slots

        let tripSlotSize = tripLabel == nil ? 0 : 1

        var remainingSlots = max(0, maxPreviewSlots - tripSlotSize)

        func take(_ events: [PlannerEvent]) -> [PlannerEvent] {
            guard remainingSlots > 0, !events.isEmpty else {
                return []
            }

            let slice = Array(events.prefix(remainingSlots))
            remainingSlots -= slice.count

            return slice
        }

        let birthdays = take(filteredBirthdayChips)
        let chips = take(filteredEventChips)

        let calendarPreview = take(calendarEvents)
        let timedUniquePreview = take(timedUniqueEvents)
        let untimedUniquePreview = take(untimedUniqueEvents)
        let timedRoutinePreview = take(timedRoutineRecords)
        let untimedRoutinePreview = take(untimedRoutineRecords)

        // MARK: Sort Planner Preview

        var plannerPreview: [PlannerEvent] = []

        plannerPreview.reserveCapacity(
            calendarPreview.count
                + timedUniquePreview.count
                + untimedUniquePreview.count
                + timedRoutinePreview.count
                + untimedRoutinePreview.count
        )

        plannerPreview.append(contentsOf: calendarPreview)
        plannerPreview.append(contentsOf: timedUniquePreview)
        plannerPreview.append(contentsOf: untimedUniquePreview)
        plannerPreview.append(contentsOf: timedRoutinePreview)
        plannerPreview.append(contentsOf: untimedRoutinePreview)

        plannerPreview.sort {
            $0.sortDate < $1.sortDate
        }

        let totalItemCount =
            tripSlotSize
            + filteredBirthdayChips.count
            + filteredEventChips.count
            + filteredPlannerEventCount

        let previewItemCount =
            tripSlotSize
            + birthdays.count
            + chips.count
            + plannerPreview.count

        self.tripLabel = tripLabel
        self.birthdayEvents = birthdays
        self.chipEvents = chips
        self.plannerEvents = plannerPreview
        self.remainingItemCount = totalItemCount - previewItemCount
        self.hasItems = totalItemCount > 0
    }

    let tripLabel: String?
    let birthdayEvents: [PlannerEvent]
    let chipEvents: [PlannerEvent]
    let plannerEvents: [PlannerEvent]
    let remainingItemCount: Int
    let hasItems: Bool

    // MARK: - Computed Properties

    var remainingPlansLabel: LocalizedStringKey {
        guard remainingItemCount > 0 else {
            return hasItems ? "No more plans" : "No plans"
        }

        return "^[\(remainingItemCount) more plan](inflect: true)"
    }
}
