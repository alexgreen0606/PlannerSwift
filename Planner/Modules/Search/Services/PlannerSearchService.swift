//
//  PlannerSearchService.swift
//  Planner
//
//  Created by Alex Green on 4/2/26.
//

import EventKit
import SwiftData
import SwiftDate

@ModelActor
actor PlannerSearchService {
    func search(
        query: PlannerSearchQuery?,
        ekEventStore: EKEventStore,
        settings: PlannerSettings
    ) -> [String: [String]] {
        do {
            let text = query?.text ?? ""
            let filteredCalendarIds = query?.filteredCalendarIds ?? []
            let filterPast = query?.filterPast ?? false

            let onlySearchCalendar =
                filteredCalendarIds.count > 0 && text.isEmpty

            // Store loaded planner days for efficiency.
            var plannerCache: [String: DateInRegion] = [:]

            // Stores calendarEventExternalIds that actually exist within a given planner day.
            var calendarDayCache: [String: Set<String>] = [:]

            var datestampScores: [String: Double] = [:]

            // ------------------------------------------------------------------
            // Phase 1: Search for matching trips.
            // ------------------------------------------------------------------

            let trips =
                !onlySearchCalendar
                ? try modelContext.fetch(FetchDescriptor<Trip>()) : []

            for trip in trips {
                guard let score = trip.searchQueryScore(query) else {
                    continue
                }

                guard let query else {
                    datestampScores[trip.firstDatestamp, default: 0] += score
                    continue
                }

                // Find the first day in the trip that matches the timeframe.
                let firstValidPlanner = trip.sortedPlanners.first(where: {
                    planner in
                    plannerCache[planner.datestamp] = planner.datestamp
                        .startOfDay(in: planner.region(settings: settings))

                    if query.filterPast,
                        planner.datestamp < query.todayStartOfDay.datestamp
                    {
                        return true
                    } else if planner.datestamp
                        >= query.todayStartOfDay.datestamp
                    {
                        return true
                    }
                    return false
                })

                if let firstValidPlanner {
                    datestampScores[firstValidPlanner.datestamp, default: 0] +=
                        score
                }
            }

            // ------------------------------------------------------------------
            // Phase 2: Find planners with matching locations.
            // ------------------------------------------------------------------

            var filteredPlanners: [Planner] = []

            if !onlySearchCalendar {
                filteredPlanners = try modelContext.fetch(
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
                datestampScores[planner.datestamp, default: 0] += score
            }

            // ------------------------------------------------------------------
            // Phase 3: Find planner events with matching locations or titles.
            // ------------------------------------------------------------------

            var filteredPlannerEvents: [PlannerEvent] = []

            if !onlySearchCalendar {
                filteredPlannerEvents = try modelContext.fetch(
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

                guard let time = plannerEvent.time else {
                    if let datestamp = plannerEvent.datestamp {
                        datestampScores[datestamp, default: 0] += score
                    }
                    continue
                }

                // Add the datestamps that own this event.
                try updateDatestamps(
                    with: time,
                    datestampScores: &datestampScores,
                    plannerCache: &plannerCache,
                    calendarDayCache: &calendarDayCache,
                    settings: settings,
                    homeRegion: settings.homeRegion,
                    todaystamp: query?.todayStartOfDay.datestamp,
                    filterPast: filterPast,
                    score: score,
                    ekEventStore: ekEventStore
                )
            }

            // ------------------------------------------------------------------
            // Phase 4: Find calendar events with matching locations or titles.
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
            )

            for calendarEvent in calendarEvents {
                guard let score = calendarEvent.searchQueryScore(query) else {
                    continue
                }

                // Add the datestamps that own this event.
                try updateDatestamps(
                    with: calendarEvent.startDate,
                    calendarEvent: calendarEvent,
                    datestampScores: &datestampScores,
                    plannerCache: &plannerCache,
                    calendarDayCache: &calendarDayCache,
                    settings: settings,
                    homeRegion: settings.homeRegion,
                    todaystamp: query?.todayStartOfDay.datestamp,
                    filterPast: filterPast,
                    score: score,
                    ekEventStore: ekEventStore
                )
            }

            // ------------------------------------------------------------------
            // Phase 5: Assemble the data and display the top 10 results.
            // ------------------------------------------------------------------

            if query?.isSearching == true {
                return buildSearchResults(
                    from: datestampScores,
                    filterPast: filterPast
                )
            } else {
                return buildDefaultResults(
                    from: datestampScores,
                    filterPast: filterPast
                )
            }
        } catch {
            assertionFailure("ERROR searchPlanner: \(error)")
            return [:]
        }
    }

    // MARK: - Helper Functions

    private func updateDatestamps(
        with startDate: Date,
        calendarEvent: EKEvent? = nil,
        datestampScores: inout [String: Double],
        plannerCache: inout [String: DateInRegion],
        calendarDayCache: inout [String: Set<String>],
        settings: PlannerSettings,
        homeRegion: Region,
        todaystamp: String?,
        filterPast: Bool,
        score: Double,
        ekEventStore: EKEventStore
    ) throws {
        let possibleDatestamps = getSortedPossibleDatestamps(
            for: startDate,
            ending: calendarEvent?.endDate
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
                    for: startDate,
                    includes: cachedPlannerStartOfDay,
                    calendarEvent: calendarEvent,
                    calendarDayCache: &calendarDayCache,
                    ekEventStore: ekEventStore,
                    settings: settings
                ) {
                    datestampScores[datestamp, default: 0] += score
                }
                continue
            }

            // Load the planner from storage to determine if it owns the event.

            let planners = try modelContext.fetch(
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

            if range(
                for: startDate,
                includes: plannerDay,
                calendarEvent: calendarEvent,
                calendarDayCache: &calendarDayCache,
                ekEventStore: ekEventStore,
                settings: settings
            ) {
                datestampScores[datestamp, default: 0] += score
            }
        }
    }

    private func buildSearchResults(
        from datestampScores: [String: Double],
        filterPast: Bool
    )
        -> [String: [String]]
    {
        let topDatestamps =
            datestampScores
            .sorted {
                if $0.value == $1.value {
                    // Scores are equal. Sort by datestamp filterPast.
                    return filterPast
                        ? $0.key > $1.key  // descending
                        : $0.key < $1.key  // ascending
                }
                // Sort by scores descending.
                return $0.value > $1.value
            }
            .prefix(10)
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

    private func buildDefaultResults(
        from datestampScores: [String: Double],
        filterPast: Bool
    )
        -> [String: [String]]
    {
        let limitedDatestamps =
            datestampScores.keys
            .sorted {
                filterPast
                    ? $0 > $1  // descending
                    : $0 < $1  // ascending
            }
            .prefix(10)

        return Dictionary(grouping: limitedDatestamps) {
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

    private func range(
        for start: Date,
        includes plannerDay: DateInRegion,
        calendarEvent: EKEvent?,
        calendarDayCache: inout [String: Set<String>],
        ekEventStore: EKEventStore,
        settings: PlannerSettings
    ) -> Bool {
        let dayStart = plannerDay.date
        let nextDayStart = (plannerDay + 1.days).date

        // Safe guard.
        // Checks that calendar all-day events truly land within the planner's time frame.
        // All-day event start and end dates vary based on the predicate that is used to call it.
        // This predicate is planner-specific and guaranteed to be accurate.
        if let calendarEvent, calendarEvent.isAllDay {
            let eventSet = {
                if let existing = calendarDayCache[plannerDay.datestamp] {
                    return existing
                }

                let calendarDayEvents = ekEventStore.events(
                    matching: ekEventStore.predicateForEvents(
                        withStart: dayStart,
                        end: nextDayStart,
                        calendars: nil
                    )
                ).filter {
                    !settings.hiddenCalendarIds.contains(
                        $0.calendar.calendarIdentifier
                    )
                }

                let eventSet = Set(
                    calendarDayEvents.compactMap(
                        \.calendarItemExternalIdentifier
                    )
                )
                calendarDayCache[plannerDay.datestamp] = eventSet
                return eventSet
            }()

            return eventSet.contains(
                calendarEvent.calendarItemExternalIdentifier
            )
        }

        let end = calendarEvent?.endDate ?? start

        return start < nextDayStart && end >= dayStart
    }
}
