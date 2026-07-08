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
        query: SearchQuery,
        ekEventStore: EKEventStore,
        settings: Settings
    )
        -> /// Maps years to lists of planner datestamps that contain data matching the query.
        [String: [String]]
    {
        var scores: [String: Double] = [:]

        do {
            var plannerDayCache: [String: DateInRegion] = [:]

            if query.calendarIds.isEmpty {

                // Search trips.
                try searchTrips(
                    query: query,
                    scores: &scores,
                    plannerDayCache: &plannerDayCache,
                    settings: settings
                )

                // Search planners.
                if !query.text.isEmpty {
                    try searchPlanners(
                        query: query,
                        scores: &scores,
                        plannerDayCache: &plannerDayCache,
                        settings: settings
                    )
                }

                // Search planner events.
                try searchPlannerEvents(
                    query: query,
                    scores: &scores,
                    plannerDayCache: &plannerDayCache,
                    settings: settings
                )

                // Search weekdays.
                searchWeekdays(query: query, scores: &scores)

                // Search months.
                searchMonths(query: query, scores: &scores)
            }

            // Search calendar events.
            try searchEkEvents(
                query: query,
                scores: &scores,
                plannerDayCache: &plannerDayCache,
                ekEventStore: ekEventStore,
                settings: settings
            )

        } catch {
            assertionFailure("ERROR SearchService search: \(error)")
        }

        return buildSearchResults(
            from: scores,
            query: query
        )
    }

    // MARK: - Search Functions

    private func searchTrips(
        query: SearchQuery,
        scores: inout [String: Double],
        plannerDayCache: inout [String: DateInRegion],
        settings: Settings
    ) throws {
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

                if query.containsDatestamp(planner.datestamp) {
                    scores[planner.datestamp, default: 0] += score
                }
            }
        }
    }

    private func searchPlanners(
        query: SearchQuery,
        scores: inout [String: Double],
        plannerDayCache: inout [String: DateInRegion],
        settings: Settings
    ) throws {
        let filteredPlanners = try modelContext.fetch(
            FetchDescriptor<Planner>(
                predicate: Planner.planners(matching: query)
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
        query: SearchQuery,
        scores: inout [String: Double],
        plannerDayCache: inout [String: DateInRegion],
        settings: Settings
    ) throws {
        let homeRegion = settings.homeRegion

        let filteredPlannerEvents = try modelContext.fetch(
            FetchDescriptor<PlannerEvent>(
                predicate: PlannerEvent.plannerEvents(matching: query)
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

    private func searchWeekdays(
        query: SearchQuery,
        scores: inout [String: Double]
    ) {
        let today = query.todayStartOfDay

        guard let todayWeekday = Weekday.forDatestamp(today.datestamp)
        else {
            return
        }

        for weekday in Weekday.allCases {
            guard let weekdayScore = query.score(for: weekday.label) else {
                continue
            }

            var day: DateInRegion

            if query.past {
                let daysSince = (todayWeekday.index - weekday.index + 7) % 7
                day = today - daysSince.days
            } else {
                let daysUntil = (weekday.index - todayWeekday.index + 7) % 7
                day = today + daysUntil.days
            }

            for _ in 0..<Self.MAX_RESULTS {
                let datestamp = day.datestamp

                scores[datestamp, default: 0] += weekdayScore

                day =
                    query.past
                    ? day - 1.weeks
                    : day + 1.weeks
            }
        }
    }

    private func searchMonths(
        query: SearchQuery,
        scores: inout [String: Double]
    ) {
        let today = query.todayStartOfDay

        for month in Month.allCases {
            guard let monthScore = query.score(for: month.label) else {
                continue
            }

            var day: DateInRegion
            var year = today.year

            if query.past {
                if month.number > today.month {
                    // Month is after this month and we are searching the past.
                    // Jump to last year.
                    year -= 1
                }

                day = DateInRegion(
                    year: year,
                    month: month.number,
                    day: 1,
                    region: today.region
                )
                .dateAtEndOf(.month)

            } else {
                if month.number < today.month {
                    // Month is before this month and we are searching the future.
                    // Jump to next year.
                    year += 1
                }

                day = DateInRegion(
                    year: year,
                    month: month.number,
                    day: 1,
                    region: today.region
                )
            }

            while day.month == month.number {
                let datestamp = day.datestamp

                if query.containsDatestamp(datestamp) {
                    scores[datestamp, default: 0] += monthScore
                }

                day =
                    query.past
                    ? day - 1.days
                    : day + 1.days
            }
        }
    }

    private func searchEkEvents(
        query: SearchQuery,
        scores: inout [String: Double],
        plannerDayCache: inout [String: DateInRegion],
        ekEventStore: EKEventStore,
        settings: Settings
    ) throws {
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
            let parentDatestamps = try getPlannerDatestamps(
                startTime: ekEvent.startDate,
                endTime: ekEvent.endDate,
                query: query,
                plannerDayCache: &plannerDayCache,
                homeRegion: settings.homeRegion,
                settings: settings
            )

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
        query: SearchQuery
    ) -> [String: [String]] {
        let topDatestamps =
            scores
            .sorted {
                if query.text.isEmpty || $0.value == $1.value {
                    // Scores are equal or user is not searching for specific text. Sort by datestamp.
                    return query.past
                        ? $0.key > $1.key
                        : $0.key < $1.key
                }

                // Sort highest scores at the top.
                return $0.value > $1.value
            }
            .prefix(Self.MAX_RESULTS)
            .map(\.key)

        return Dictionary(grouping: topDatestamps) {
            datestamp in
            String(datestamp.prefix(4))
        }.mapValues { datestamps in
            datestamps.sorted {
                query.past
                    ? $0 > $1
                    : $0 < $1
            }
        }
    }

    private func getPlannerDatestamps(
        startTime time: Date,
        endTime: Date? = nil,
        query: SearchQuery,
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
        where query.containsDatestamp(datestamp) {

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
