//
//  SearchService.swift
//  Planner
//
//  Created by Alex Green on 4/2/26.
//

import EventKit
import SwiftData
import SwiftDate

// TODO: add a date formatter check for weekdays and dates

@ModelActor
actor SearchService {
    func search(
        query: SearchQuery,
        ekEventStore: EKEventStore,
        settings: Settings
    )
        -> /// Maps years to lists of planner datestamps that contain data matching the query.
        [String: [String]]
    {
        do {
            var datestampScores: [String: Double] = [:]

            var plannerDayCache: [String: DateInRegion] = [:]

            let searchingCalendar = !query.calendarIds.isEmpty

            // ------------------------------------------------------------------
            // Phase 1: Search trips.
            // ------------------------------------------------------------------

            if !searchingCalendar {
                let filteredTrips = try modelContext.fetch(
                    FetchDescriptor<Trip>(
                        predicate: Trip.trips(matching: query)
                    )
                )

                for trip in filteredTrips {
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
            // Phase 2: Search planners.
            // ------------------------------------------------------------------

            if !searchingCalendar && !query.text.isEmpty {
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
            // Phase 3: Search planner events.
            // ------------------------------------------------------------------

            if !searchingCalendar {
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
                        score: score,
                        query: query,
                        datestampScores: &datestampScores,
                        plannerDayCache: &plannerDayCache,
                        homeRegion: settings.homeRegion,
                        settings: settings,
                    )
                }
            }

            // ------------------------------------------------------------------
            // Phase 4: Search calendar events.
            // ------------------------------------------------------------------

            let filteredEkEvents = ekEventStore.events(
                matching: ekEventStore.predicateForEvents(
                    withStart: query.startDate,
                    end: query.endDate,
                    calendars: nil
                )
            ).filter {
                !settings.hiddenCalendarIds.contains(
                    $0.calendar.calendarIdentifier
                )
            }

            for ekEvent in filteredEkEvents {
                guard let score = ekEvent.searchQueryScore(query) else {
                    continue
                }

                // Add the datestamps that own this event.
                try updateDatestampsForTimedEvent(
                    with: ekEvent.startDate,
                    ekEvent: ekEvent,
                    score: score,
                    query: query,
                    datestampScores: &datestampScores,
                    plannerDayCache: &plannerDayCache,
                    homeRegion: settings.homeRegion,
                    settings: settings
                )
            }

            // ------------------------------------------------------------------
            // Final: Return the top 20 results.
            // ------------------------------------------------------------------

            return buildSearchResults(
                from: datestampScores,
                query: query
            )
        } catch {
            assertionFailure("ERROR SearchService search: \(error)")
        }

        return [:]
    }

    // MARK: - Helper Functions

    private func buildSearchResults(
        from datestampScores: [String: Double],
        query: SearchQuery
    ) -> [String: [String]] {
        let isSearchingPast = query.past

        let topDatestamps =
            datestampScores
            .sorted {
                if query.text.isEmpty || $0.value == $1.value {
                    // Scores are equal or user is not searching for specific text. Sort by datestamp.
                    return isSearchingPast
                        ? $0.key > $1.key
                        : $0.key < $1.key
                }

                // Sort highest scores at the top.
                return $0.value > $1.value
            }
            .prefix(20)
            .map { $0.key }

        return Dictionary(grouping: topDatestamps) {
            datestamp in
            String(datestamp.prefix(4))
        }.mapValues { datestamps in
            datestamps.sorted {
                isSearchingPast
                    ? $0 > $1
                    : $0 < $1
            }
        }
    }

    private func updateDatestampsForTimedEvent(
        with time: Date,
        ekEvent: EKEvent? = nil,
        score: Double,
        query: SearchQuery,
        datestampScores: inout [String: Double],
        plannerDayCache: inout [String: DateInRegion],
        homeRegion: Region,
        settings: Settings,
    ) throws {
        let possibleDatestamps = getSortedPossibleDatestamps(
            for: time,
            ending: ekEvent?.endDate
        )

        for datestamp in possibleDatestamps
        where query.containsDatestamp(datestamp) {

            // Use the cached start of day to determine if the planner owns this event.
            if let cachedPlannerDay = plannerDayCache[
                datestamp
            ] {
                if cachedPlannerDay.includes(
                    startTime: time,
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

            plannerDayCache[datestamp] = plannerDay

            if plannerDay.includes(
                startTime: time,
                endTime: ekEvent?.endDate
            ) {
                datestampScores[datestamp, default: 0] += score
            }
        }
    }
}
