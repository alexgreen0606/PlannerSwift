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
            let homeRegion = settings.homeRegion

            let onlySearchCalendar =
                filteredCalendarIds.count > 0 && text.isEmpty

            var datestamps: Set<String> = []

            // ------------------------------------------------------------------
            // Phase 1: Find planners with matching locations.
            // ------------------------------------------------------------------

            var filteredPlanners: [Planner] = []

            if filteredCalendarIds.isEmpty, !text.isEmpty {
                filteredPlanners = try fetch(
                    FetchDescriptor<Planner>(
                        predicate: #Predicate<Planner> { planner in
                            if let location = planner.location {
                                return location.name.contains(text)
                            } else {
                                return text.isEmpty
                            }
                        }
                    )
                )
            }

            for planner in filteredPlanners {
                datestamps.insert(planner.datestamp)
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
                // Filter out events that don't match the text query (too complex to be used in the predicate)
                .filter { event in
                    event.containsText(text)
                }
            }

            // Store loaded planners for efficiency.
            var plannerCache: [String: DateInRegion] = [:]

            for plannerEvent in filteredPlannerEvents {
                // Add the datestamps that own this event.
                try updateDatestamps(
                    with: plannerEvent.date,
                    datestamps: &datestamps,
                    plannerCache: &plannerCache,
                    settings: settings,
                    homeRegion: homeRegion
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

            for calendarEvent in calendarEvents
            where calendarEvent.containsText(text)
                && !calendarEvent.calendar.isHidden(
                    filteredCalendarIds: filteredCalendarIds
                )
            {
                // Add the datestamps that own this event.
                try updateDatestamps(
                    with: calendarEvent.startDate,
                    ending: calendarEvent.endDate,
                    datestamps: &datestamps,
                    plannerCache: &plannerCache,
                    settings: settings,
                    homeRegion: homeRegion,
                )
            }

            // ------------------------------------------------------------------
            // Phase 4: Assemble the data and display the top 10 results.
            // ------------------------------------------------------------------

            let todaystamp = DateInRegion(region: .local).toFormat(
                "yyyy-MM-dd",
                locale: Locale.current
            )

            let filteredDatestamps = datestamps.filter { datestamp in
                if text.isEmpty {
                    // If there is no text parameter, only display current and future dates.
                    return datestamp >= todaystamp
                }
                return true
            }

            let limitedDatestamps =
                filteredDatestamps
                .sorted()
                .prefix(10)

            let groupedByYear = Dictionary(grouping: limitedDatestamps) {
                datestamp in
                String(datestamp.prefix(4))
            }.mapValues { Array($0).sorted() }

            return groupedByYear
        } catch {
            assertionFailure("ERROR searchPlanner.searchPlanner: \(error)")
            return [:]
        }
    }

    // MARK: - Helper Functions

    private func updateDatestamps(
        with startDate: Date,
        ending endDate: Date? = nil,
        datestamps: inout Set<String>,
        plannerCache: inout [String: DateInRegion],
        settings: PlannerSettings,
        homeRegion: Region
    ) throws {
        let possibleDatestamps = getChronologicalPossibleDatestamps(
            for: startDate,
            ending: endDate
        )

        for datestamp in possibleDatestamps {
            if datestamps.contains(datestamp) {
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
                    datestamps.insert(datestamp)
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
                let plannerStartOfDay = datestamp.startOfDay(
                    in: plannerRegion
                )
            else {
                continue
            }
            plannerCache[datestamp] = plannerStartOfDay

            if range(from: startDate, to: endDate, includes: plannerStartOfDay)
            {
                datestamps.insert(datestamp)
            }
        }
    }

    private func range(
        from start: Date,
        to end: Date?,
        includes plannerStartOfDay: DateInRegion
    ) -> Bool {
        let end = end ?? start

        let dayStart = plannerStartOfDay.date
        let nextDayStart = (plannerStartOfDay + 1.days).date

        return start < nextDayStart && end >= dayStart
    }

}
