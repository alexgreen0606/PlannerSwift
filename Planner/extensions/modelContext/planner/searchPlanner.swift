//
//  searchPlanner.swift
//  Planner
//
//  Created by Alex Green on 3/17/26.
//

import EventKit
import SwiftData
import SwiftDate

// Clean

extension ModelContext {

    @MainActor
    func searchPlanner(
        with query: PlannerSearchQuery?,
        ekEventStore: EKEventStore,
        settings: PlannerSettings
    ) -> [String: [String]] {
        do {
            let text = query?.text ?? ""
            let filteredCalendarIds = query?.filteredCalendarIds ?? []
            let filterPast = query?.filterPast ?? false
            let homeRegion = settings.homeRegion

            let onlySearchCalendar =
                filteredCalendarIds.count > 0 && text.isEmpty

            // Store loaded planners for efficiency.
            var plannerCache: [String: DateInRegion] = [:]

            var datestampScores: [String: Double] = [:]

            // ------------------------------------------------------------------
            // Phase 1: Find planners with matching locations.
            // ------------------------------------------------------------------

            var filteredPlanners: [Planner] = []

            if !text.isEmpty {
                filteredPlanners = try fetch(
                    FetchDescriptor<Planner>(
                        predicate: #Predicate<Planner> { planner in
                            planner.location != nil
                        }
                    )
                )
            }

            for planner in filteredPlanners {
                guard let score = planner.searchQueryScore(query) else {
                    continue
                }

                datestampScores[planner.datestamp, default: 0] += (1.0 - score)
            }

            // ------------------------------------------------------------------
            // Phase 2: Find planner events with matching locations or titles.
            // ------------------------------------------------------------------

            var filteredPlannerEvents: [PlannerEvent] = []

            if !onlySearchCalendar {
                filteredPlannerEvents = try fetch(
                    FetchDescriptor<PlannerEvent>(
                        predicate: #Predicate<PlannerEvent> { event in
                            event.calendarItemExternalIdentifier == nil
                        }
                    )
                )
            }

            for plannerEvent in filteredPlannerEvents {
                guard let score = plannerEvent.searchQueryScore(query) else {
                    continue
                }

                // Add the datestamps that own this event.
                try updateDatestamps(
                    with: plannerEvent.date,
                    datestampScores: &datestampScores,
                    plannerCache: &plannerCache,
                    settings: settings,
                    homeRegion: homeRegion,
                    todaystamp: query?.todayStartOfDay.datestamp,
                    filterPast: filterPast,
                    score: score
                )
            }

            // ------------------------------------------------------------------
            // Phase 3: Find calendar events with matching locations or titles.
            // ------------------------------------------------------------------

            // Range: 1 year ago to 3 years from now.
            let calendarEvents = ekEventStore.events(
                matching: ekEventStore.predicateForEvents(
                    withStart: (DateInRegion() - 1.years).date,
                    end: (DateInRegion() + 3.years).date,
                    calendars: nil
                )
            )

            for calendarEvent in calendarEvents {
                guard let score = calendarEvent.searchQueryScore(query) else {
                    continue
                }

                // Add the datestamps that own this event.
                try updateDatestamps(
                    with: calendarEvent.startDate,
                    ending: calendarEvent.endDate,
                    datestampScores: &datestampScores,
                    plannerCache: &plannerCache,
                    settings: settings,
                    homeRegion: homeRegion,
                    todaystamp: query?.todayStartOfDay.datestamp,
                    filterPast: filterPast,
                    score: score
                )
            }

            // ------------------------------------------------------------------
            // Phase 4: Assemble the data and display the top 10 results.
            // ------------------------------------------------------------------

            if query?.isSearching == true {
                return buildSearchResults(from: datestampScores)
            } else {
                return buildDefaultResults(from: datestampScores)
            }
        } catch {
            assertionFailure("ERROR searchPlanner.searchPlanner: \(error)")
            return [:]
        }
    }

    // MARK: - Helper Functions

    private func updateDatestamps(
        with startDate: Date,
        ending endDate: Date? = nil,
        datestampScores: inout [String: Double],
        plannerCache: inout [String: DateInRegion],
        settings: PlannerSettings,
        homeRegion: Region,
        todaystamp: String?,
        filterPast: Bool,
        score: Double
    ) throws {
        let possibleDatestamps = getChronologicalPossibleDatestamps(
            for: startDate,
            ending: endDate
        )

        for datestamp in possibleDatestamps {

            // Skip this datestamp if it is outside the search frame.
            if let todaystamp,
                (filterPast && datestamp >= todaystamp)
                    || (!filterPast && datestamp < todaystamp)
            {
                continue
            }

            // Use the cached start of day for this datestamp to determine if the planner owns this event.
            if let cachedPlannerStartOfDay = plannerCache[
                datestamp
            ] {
                if range(
                    from: startDate,
                    to: endDate,
                    includes: cachedPlannerStartOfDay
                ) {
                    datestampScores[datestamp, default: 0] += (1.0 - score)
                }
                continue
            }

            // Load the planner from storage to determine if it owns the event.

            let planners = try fetch(
                FetchDescriptor<Planner>(
                    predicate: #Predicate<Planner> { planner in
                        planner.datestamp == datestamp
                    }
                )
            )

            let plannerRegion =
                planners.first?.region(settings: settings) ?? homeRegion

            guard
                let plannerDay = datestamp.startOfDay(
                    in: plannerRegion
                )
            else {
                continue
            }
            plannerCache[datestamp] = plannerDay

            if range(from: startDate, to: endDate, includes: plannerDay) {
                datestampScores[datestamp, default: 0] += (1.0 - score)
            }
        }
    }

    private func buildSearchResults(from datestampScores: [String: Double])
        -> [String: [String]]
    {
        let topDatestamps =
            datestampScores
            .sorted {
                $0.value > $1.value
            }
            .prefix(10)
            .map { $0.key }

        let groupedByYear = Dictionary(grouping: topDatestamps) {
            datestamp in
            String(datestamp.prefix(4))
        }.mapValues { Array($0).sorted() }

        return groupedByYear
    }

    private func buildDefaultResults(from datestampScores: [String: Double])
        -> [String: [String]]
    {
        let limitedDatestamps =
            datestampScores.keys
            .sorted()
            .prefix(10)

        let groupedByYear = Dictionary(grouping: limitedDatestamps) {
            datestamp in
            String(datestamp.prefix(4))
        }.mapValues { Array($0).sorted() }

        return groupedByYear
    }

    private func range(
        from start: Date,
        to end: Date?,
        includes plannerDay: DateInRegion
    ) -> Bool {
        let end = end ?? start

        let dayStart = plannerDay.date
        let nextDayStart = (plannerDay + 1.days).date

        return start < nextDayStart && end >= dayStart
    }

}
