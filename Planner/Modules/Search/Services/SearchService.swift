//
//  SearchService.swift
//  Planner
//
//  Created by Alex Green on 4/2/26.
//

import EventKit
import SwiftData
import SwiftDate

@ModelActor
actor SearchService {
    static let MAX_RESULTS = 31

    func search(
        query: PlannerSearchQuery,
        plannerBounds: PlannerBounds,
        todaystamp: String,
        visibleCalendars: [EKCalendar],
        ekEventStore: EKEventStore,
        settings: Settings
    )
        -> /// Maps years to lists of planner datestamps that contain data matching the query.
        StructuredDatestampsContext
    {
        var scores: [String: Double] = [:]

        do {
            var plannerDayCache: [String: DateInRegion] = [:]

            if query.calendarIds.isEmpty {

                // Search trips.
                try searchTrips(
                    query: query,
                    bounds: plannerBounds,
                    scores: &scores,
                    plannerDayCache: &plannerDayCache,
                    settings: settings
                )

                // Search planners.
                if !query.text.isEmpty {
                    try searchPlanners(
                        query: query,
                        bounds: plannerBounds,
                        scores: &scores,
                        plannerDayCache: &plannerDayCache,
                        settings: settings
                    )
                }

                // Search planner events.
                try searchPlannerEvents(
                    query: query,
                    bounds: plannerBounds,
                    scores: &scores,
                    plannerDayCache: &plannerDayCache,
                    settings: settings
                )
            }

            // Search calendar events.
            try searchEkEvents(
                query: query,
                bounds: plannerBounds,
                scores: &scores,
                plannerDayCache: &plannerDayCache,
                visibleCalendars: visibleCalendars,
                ekEventStore: ekEventStore,
                settings: settings
            )

        } catch {
            assertionFailure("ERROR SearchService search: \(error)")
        }

        return buildSearchResults(
            from: scores,
            query: query,
            todaystamp: todaystamp
        )
    }

    // MARK: - Search Functions

    private func searchTrips(
        query: PlannerSearchQuery,
        bounds: PlannerBounds,
        scores: inout [String: Double],
        plannerDayCache: inout [String: DateInRegion],
        settings: Settings
    ) throws {
        let filteredTrips = try modelContext.fetch(
            FetchDescriptor<Trip>(
                predicate: Trip.searchableTrips(within: bounds)
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

                if bounds.containsDatestamp(planner.datestamp) {
                    scores[planner.datestamp, default: 0] += score
                }
            }
        }
    }

    private func searchPlanners(
        query: PlannerSearchQuery,
        bounds: PlannerBounds,
        scores: inout [String: Double],
        plannerDayCache: inout [String: DateInRegion],
        settings: Settings
    ) throws {
        let filteredPlanners = try modelContext.fetch(
            FetchDescriptor<Planner>(
                predicate: Planner.searchablePlanners(within: bounds)
            )
        )

        for planner in filteredPlanners {
            plannerDayCache[planner.datestamp] = planner.startOfDay(
                settings: settings
            )

            if let score = planner.searchQueryScore(query) {
                scores[planner.datestamp, default: 0] += score
            }
        }
    }

    private func searchPlannerEvents(
        query: PlannerSearchQuery,
        bounds: PlannerBounds,
        scores: inout [String: Double],
        plannerDayCache: inout [String: DateInRegion],
        settings: Settings
    ) throws {
        let homeRegion = settings.homeRegion

        let filteredPlannerEvents = try modelContext.fetch(
            FetchDescriptor<PlannerEvent>(
                predicate: PlannerEvent.searchablePlannerEvents(
                    within: bounds,
                    matching: query
                )
            )
        )

        for plannerEvent in filteredPlannerEvents {
            guard let time = plannerEvent.time else {
                if let datestamp = plannerEvent.datestamp,
                    let score = plannerEvent.searchQueryScore(
                        query,
                        in: datestamp
                    )
                {
                    scores[datestamp, default: 0] += score
                }

                continue
            }

            let parentDatestamps = try getPlannerDatestamps(
                startTime: time,
                query: query,
                bounds: bounds,
                plannerDayCache: &plannerDayCache,
                homeRegion: homeRegion,
                settings: settings
            )

            for datestamp in parentDatestamps {
                if let score = plannerEvent.searchQueryScore(
                    query,
                    in: datestamp
                ) {
                    scores[datestamp, default: 0] += score
                }
            }
        }
    }

    private func searchEkEvents(
        query: PlannerSearchQuery,
        bounds: PlannerBounds,
        scores: inout [String: Double],
        plannerDayCache: inout [String: DateInRegion],
        visibleCalendars: [EKCalendar],
        ekEventStore: EKEventStore,
        settings: Settings
    ) throws {
        let filteredEkEvents = ekEventStore.events(
            matching: ekEventStore.predicateForEvents(
                withStart: bounds.minStartOfDay.date,
                end: bounds.endOfBounds,
                calendars: visibleCalendars
            )
        )

        for ekEvent in filteredEkEvents {
            let parentDatestamps: [String]

            if ekEvent.isAllDay {
                parentDatestamps = allDayDatestamps(
                    startDate: ekEvent.startDate,
                    endDate: ekEvent.endDate,
                    timeZoneId: ekEvent.timeZone?.identifier
                ).filter(bounds.containsDatestamp(_:))
            } else {
                parentDatestamps = try getPlannerDatestamps(
                    startTime: ekEvent.startDate,
                    endTime: ekEvent.endDate,
                    query: query,
                    bounds: bounds,
                    plannerDayCache: &plannerDayCache,
                    homeRegion: settings.homeRegion,
                    settings: settings
                )
            }

            // TODO: Exclude completed calendar events when the query has no search text
            // (mirrors `PlannerEvent.searchQueryScore`). Completion now lives in `EkEventPlannerState`,
            // which `EKEvent.searchQueryScore` can't see. Batch-fetch the states for these events
            // (see `EkEventPlannerState.matching(ekEvents:)`). Until then, a calendar-filtered search
            // can return days whose only matches are completed, and their previews show "No plans".
            for datestamp in parentDatestamps {
                if let score = ekEvent.searchQueryScore(
                    query,
                    in: datestamp
                ) {
                    scores[datestamp, default: 0] += score
                }
            }
        }
    }

    // MARK: - Helper Functions

    private func buildSearchResults(
        from scores: [String: Double],
        query: PlannerSearchQuery,
        todaystamp: String
    ) -> StructuredDatestampsContext {
        let topDatestamps =
            scores
            .sorted {
                let lhsIsCurrentOrFuture = $0.key >= todaystamp
                let rhsIsCurrentOrFuture = $1.key >= todaystamp

                // Priority 1: Current or future planners.
                if lhsIsCurrentOrFuture != rhsIsCurrentOrFuture {
                    return lhsIsCurrentOrFuture
                }

                // Priority 2: Not searching text/equal scores: sort chronologically.
                if query.text.isEmpty || $0.value == $1.value {
                    return $0.key < $1.key
                }

                // Priority 3: Sort by values.
                return $0.value > $1.value
            }
            .prefix(Self.MAX_RESULTS)
            .map(\.key)

        return StructuredDatestampsContext(
            datestamps: topDatestamps
        )
    }

    private func getPlannerDatestamps(
        startTime time: Date,
        endTime: Date? = nil,
        query: PlannerSearchQuery,
        bounds: PlannerBounds,
        plannerDayCache: inout [String: DateInRegion],
        homeRegion: Region,
        settings: Settings,
    ) throws -> [String] {
        var datestamps: [String] = []

        let possibleDatestamps = getSortedPossibleDatestamps(
            for: time,
            ending: endTime
        )

        for datestamp in possibleDatestamps
        where bounds.containsDatestamp(datestamp) {

            // Use the cached start of day to determine if the planner owns this event.
            if let cachedPlannerDay = plannerDayCache[
                datestamp
            ] {
                if cachedPlannerDay.includes(
                    startTime: time,
                    endTime: endTime
                ) {
                    datestamps.append(datestamp)
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
                endTime: endTime
            ) {
                datestamps.append(datestamp)
            }
        }

        return datestamps
    }
}
