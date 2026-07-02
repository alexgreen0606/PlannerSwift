//
//  PlannerSearchService.swift
//  Planner
//
//  Created by Alex Green on 4/2/26.
//

import EventKit
import SwiftData
import SwiftDate

// TODO: add a date formatter check for weekdays and dates

@ModelActor
actor PlannerSearchService {
    func search(
        query: PlannerSearchQuery,
        ekEventStore: EKEventStore,
        settings: PlannerSettings
    )
        -> /// Maps years to lists of planner datestamps that contain data matching the query.
        [String: [String]]
    {
        do {
            let text = query.text
            let filteredCalendarIds = query.calendarIds
            let filterPast = query.past

            let onlySearchCalendar =
                filteredCalendarIds.count > 0 && text.isEmpty

            // Store loaded planner start of days for efficiency.
            var plannerDayCache: [String: DateInRegion] = [:]

            var datestampScores: [String: Double] = [:]

            // ------------------------------------------------------------------
            // Phase 1: Search for matching trips.
            // ------------------------------------------------------------------

            if !onlySearchCalendar {
                let trips = try modelContext.fetch(
                    FetchDescriptor<Trip>(
                        predicate: Trip.trips(matching: query)
                    )
                )

                for trip in trips {
                    guard let score = trip.searchQueryScore(query) else {
                        continue
                    }

                    for planner in trip.sortedPlanners {
                        plannerDayCache[planner.datestamp] = planner.startOfDay(
                            settings: settings
                        )

                        guard query.containsDatestamp(planner.datestamp) else {
                            continue
                        }

                        datestampScores[planner.datestamp, default: 0] += score
                    }
                }
            }

            // ------------------------------------------------------------------
            // Phase 2: Search for matching planners.
            // ------------------------------------------------------------------

            if !onlySearchCalendar {
                let filteredPlanners = try modelContext.fetch(
                    FetchDescriptor<Planner>(
                        predicate: Planner.planners(matching: query)
                    )
                )

                for planner in filteredPlanners {
                    guard let score = planner.searchQueryScore(query) else {
                        continue
                    }

                    datestampScores[planner.datestamp, default: 0] += score
                }
            }

            // ------------------------------------------------------------------
            // Phase 3: Search for matching planner events.
            // ------------------------------------------------------------------

            if !onlySearchCalendar {
                let filteredPlannerEvents = try modelContext.fetch(
                    FetchDescriptor<PlannerEvent>(
                        predicate: PlannerEvent.plannerEvents(matching: query)
                    )
                )

                for plannerEvent in filteredPlannerEvents {
                    guard let score = plannerEvent.searchQueryScore(query)
                    else {
                        continue
                    }

                    guard let time = plannerEvent.time else {
                        if let datestamp = plannerEvent.datestamp {
                            datestampScores[datestamp, default: 0] += score
                        }

                        continue
                    }

                    // Add the datestamps that own this event.
                    try updateDatestampsForTimedEvent(
                        with: time,
                        datestampScores: &datestampScores,
                        plannerCache: &plannerDayCache,
                        settings: settings,
                        homeRegion: settings.homeRegion,
                        query: query,
                        score: score
                    )
                }
            }

            // ------------------------------------------------------------------
            // Phase 4: Search for matching calendar events.
            // ------------------------------------------------------------------

            let startDate =
                filterPast
                ? (DateInRegion() - 2.years).date : DateInRegion().date
            let endDate =
                filterPast
                ? DateInRegion().date : (DateInRegion() + 2.years).date

            // Range: 1 year ago to 3 years from now.
            let calendarEvents = ekEventStore.events(
                matching: ekEventStore.predicateForEvents(
                    withStart: startDate,
                    end: endDate,
                    calendars: nil
                )
            ).filter {
                !settings.hiddenCalendarIds.contains(
                    $0.calendar.calendarIdentifier
                )
            }

            for calendarEvent in calendarEvents {
                guard let score = calendarEvent.searchQueryScore(query) else {
                    continue
                }

                // Add the datestamps that own this event.
                try updateDatestampsForTimedEvent(
                    with: calendarEvent.startDate,
                    ekEvent: calendarEvent,
                    datestampScores: &datestampScores,
                    plannerCache: &plannerDayCache,
                    settings: settings,
                    homeRegion: settings.homeRegion,
                    query: query,
                    score: score
                )
            }

            // ------------------------------------------------------------------
            // Final: Assemble the data and display the top 20 results.
            // ------------------------------------------------------------------

            return buildSearchResults(
                from: datestampScores,
                filterPast: filterPast,
                ignoreScores: query.text.isEmpty
            )
        } catch {
            assertionFailure("ERROR PlannerSearchService search: \(error)")
            return [:]
        }
    }

    // MARK: - Helper Functions
    
    private func buildSearchResults(
        from datestampScores: [String: Double],
        filterPast: Bool,
        ignoreScores: Bool
    )
        -> [String: [String]]
    {
        let topDatestamps =
            datestampScores
            .sorted {
                if ignoreScores || $0.value == $1.value {
                    // Scores are equal or ignored. Sort by datestamp.
                    return filterPast
                        ? $0.key > $1.key  // descending
                        : $0.key < $1.key  // ascending
                }
                // Sort by scores descending.
                return $0.value > $1.value
            }
            .prefix(20)
            .map { $0.key }

        return Dictionary(grouping: topDatestamps) {
            datestamp in
            String(datestamp.prefix(4))
        }.mapValues { datestamps in
            datestamps.sorted {
                filterPast
                    ? $0 > $1  // descending
                    : $0 < $1  // ascending
            }
        }
    }

    private func updateDatestampsForTimedEvent(
        with startDate: Date,
        ekEvent: EKEvent? = nil,
        datestampScores: inout [String: Double],
        plannerCache: inout [String: DateInRegion],
        settings: PlannerSettings,
        homeRegion: Region,
        query: PlannerSearchQuery,
        score: Double
    ) throws {
        let possibleDatestamps = getSortedPossibleDatestamps(
            for: startDate,
            ending: ekEvent?.endDate
        )

        for datestamp in possibleDatestamps
        where query.containsDatestamp(datestamp) {

            // Use the cached start of day for this datestamp to determine if the planner owns this event.
            if let cachedPlannerStartOfDay = plannerCache[
                datestamp
            ] {
                if cachedPlannerStartOfDay.includes(
                    startTime: startDate,
                    endTime: ekEvent?.endDate
                ) {
                    datestampScores[datestamp, default: 0] += score
                }
                continue
            }

            // Load the planner to determine if it owns the event.

            let planner = try modelContext.fetch(
                FetchDescriptor<Planner>(
                    predicate: Planner.planners(datestamp: datestamp)
                )
            ).first

            let plannerDay = datestamp.startOfDay(
                in: planner?.region(settings: settings) ?? homeRegion
            )

            plannerCache[datestamp] = plannerDay

            if plannerDay.includes(
                startTime: startDate,
                endTime: ekEvent?.endDate
            ) {
                datestampScores[datestamp, default: 0] += score
            }
        }
    }
}
