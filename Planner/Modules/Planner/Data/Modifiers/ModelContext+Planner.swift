//
//  ModelContext+Planner.swift
//  Planner
//
//  Created by Alex Green on 2/12/26.
//

import EventKit
import SwiftData
import SwiftDate
import SwiftUI

extension ModelContext {
    // MARK: - DEDUPLICATION

    @MainActor
    private func deduplicatePlanner(
        planners: [Planner]
    ) -> Planner? {
        guard let merged = planners.first else {
            return nil
        }

        for planner in planners.dropFirst()
        where planner.datestamp == merged.datestamp {
            // Merge locations.
            if let location = planner.location, merged.location == nil {
                merged.location = location
                location.planners.safeAppend(merged)
                planner.location = nil
            }

            // Merge routines.
            if let routine = planner.routine, merged.routine == nil {
                merged.routine = routine
                routine.planners.safeAppend(merged)
                planner.routine = nil
            }

            // Merge trips.
            if let trip = planner.trip, merged.trip == nil {
                merged.trip = trip
                trip.planners.safeAppend(merged)
                planner.trip = nil
            }

            // Merge routine records. Only carry over variants.

            let variantsToCarryOver = planner.safeRoutineEventRecordContexts
                .filter(\.isVariant)

            let variantIdsToCarryOver = Set(
                variantsToCarryOver.compactMap {
                    $0.routineEvent?.routineEventContext?.stableId
                }
            )

            // Remove carried variants from old planner.
            planner.routineEventRecordContexts?.removeAll { context in
                guard
                    let id = context.routineEvent?.routineEventContext?.stableId
                else {
                    return false
                }

                return variantIdsToCarryOver.contains(id)
            }

            // Delete conflicting variants from merged.
            for existing in merged.safeRoutineEventRecordContexts {
                if let id = existing.routineEvent?.routineEventContext?
                    .stableId,
                    variantIdsToCarryOver.contains(id)
                {
                    delete(existing)
                }
            }

            // Move variants to merged.
            for context in variantsToCarryOver {
                context.planner = merged
                merged.routineEventRecordContexts.safeAppend(context)
            }

            delete(planner)
        }

        safeSave("ModelContext+Planner deduplicatePlanner")

        return merged
    }

    // MARK: - CREATE

    private func createPlanner(
        for datestamp: String,
        skipSave: Bool = false
    ) -> Planner {
        let routine = getRoutine(for: datestamp.weekday)!

        let planner = Planner(
            datestamp: datestamp,
            routine: routine
        )

        insert(planner)

        if !skipSave {
            safeSave("ModelContext+Planner createPlanner")
        }

        return planner
    }

    // MARK: - READ

    @MainActor
    func getPlanner(
        for datestamp: String
    ) -> Planner {
        do {
            let planners = try fetch(
                FetchDescriptor<Planner>(
                    predicate: Planner.planners(datestamp: datestamp)
                )
            )

            return planners.first ?? createPlanner(for: datestamp)
        } catch {
            return createPlanner(for: datestamp)
        }
    }

    @MainActor
    func getBulkPlanners(
        for datestamps: Set<String>
    ) -> [Planner] {
        do {
            // Load in planners that already exist in storage.

            let existingPlanners = try fetch(
                FetchDescriptor<Planner>(
                    predicate: Planner.planners(datestamps: datestamps)
                )
            )

            // Deduplicate existing planners.

            var allPlanners: [Planner] = []

            let plannersByDatestamp = Dictionary(
                grouping: existingPlanners,
                by: \.datestamp
            )

            for planners in plannersByDatestamp.values {
                if planners.count > 1 {
                    if let planner = deduplicatePlanner(planners: planners) {
                        allPlanners.append(planner)
                    }
                } else if let planner = planners.first {
                    allPlanners.append(planner)
                }
            }

            // Create new planners that don't exist yet.

            let existingDatestamps = Set(plannersByDatestamp.keys)

            for datestamp in datestamps.subtracting(existingDatestamps) {
                allPlanners.append(
                    createPlanner(for: datestamp, skipSave: true)
                )
            }

            return allPlanners

        } catch {
            return []
        }
    }

    /// Fetches the start of days for all planners that can hold an event with the given absolute point in time.
    /// When no time is given, the datestamp will be used to load that planner and calculate it's start of day.
    @MainActor
    func getSortedPlannerStartOfDays(
        for time: Date?,
        endTime: Date? = nil,
        datestamp: String? = nil,
        settings: Settings
    ) -> [DateInRegion] {
        guard let time else {
            guard let datestamp else {
                return []
            }

            let planner = getPlanner(for: datestamp)

            // Event has no time. Return the start of day for the event's assigned planner.
            return [
                planner.startOfDay(settings: settings)
            ]
        }

        let sortedPossibleDatestamps =
            getSortedPossibleDatestamps(for: time, ending: endTime)

        var sortedStartOfDays: [DateInRegion] = []

        // Gather all planner start of days that contain the event.
        for datestamp in sortedPossibleDatestamps {
            let planner = getPlanner(for: datestamp)

            let startOfDay = planner.startOfDay(settings: settings)

            let eventExistsInPlanner = {
                if let endTime,
                    startOfDay.includes(startTime: time, endTime: endTime)
                {
                    return true
                }

                return time.belongsToPlanner(startOfDay: startOfDay)
            }()

            if eventExistsInPlanner {
                sortedStartOfDays.append(startOfDay)
            }
        }

        return sortedStartOfDays
    }

    @MainActor
    func getUpperSortDate(for startOfDay: DateInRegion) -> Date {
        let listEvents = getSortedListEvents(on: startOfDay)
        return generatePlannerEventSortDate(
            at: 0,
            in: listEvents,
            startOfDay: startOfDay
        )
    }

    // MARK: - UPDATE

    @MainActor
    func updatePlannerLocation(
        for planner: Planner,
        to newLocation: Location?,
        plannerService: PlannerService
    ) {
        planner.location = newLocation
        safeSave("ModelContext+Planner updatePlannerLocation")

        /// Freshness is based on location and date for weather and calendar.
        /// No need to invalidate anything.
        plannerService.syncPlanner(planner)
    }

    @MainActor
    func togglePlannerRoutineExclusion(
        for planner: Planner,
        plannerService: PlannerService
    ) {
        planner.excludeRoutine = !planner.safeExcludeRoutine

        if let trip = planner.trip,
            trip.excludeRoutines == planner.excludeRoutine
        {
            // Revert flag back to nil so it inherits the exclusion state from the trip.
            planner.excludeRoutine = nil
        }

        safeSave("ModelContext+Planner togglePlannerRoutineExclusion")

        // Sync the planner's routine.
        plannerService.refreshPlannerRoutine(
            planner: planner
        )
    }
}
