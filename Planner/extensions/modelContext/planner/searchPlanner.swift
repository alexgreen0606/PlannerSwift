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

            var datestamps: Set<String> = []

            // ------------------------------------------------------------------
            // Phase 1: Find planners with matching locations.
            // ------------------------------------------------------------------
            
            var filteredPlanners: [Planner] = []

            if filteredCalendarIds.isEmpty {
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

            var filteredPlannerEvents = try fetch(
                FetchDescriptor<PlannerEvent>()
            )

            if !text.isEmpty {
                filteredPlannerEvents = filteredPlannerEvents.filter { event in
                    event.containsText(text)
                }
            }

            // Store loaded planners for efficiency.
            var plannerCache: [String: DateInRegion] = [:]

            for plannerEvent in filteredPlannerEvents {
                if plannerEvent.calendarItemExternalIdentifier != nil {
                    // Skip calendar events. These will be assessed below.
                    continue
                }

                // Add the planner datestamps that own this event.
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
            where calendarEvent.containsText(text) {
                if calendarEvent.calendar.isHidden(
                    filteredCalendarIds: filteredCalendarIds
                ) {
                    // Skip events whose calendar is hidden.
                    continue
                }

                // Add the planner datestamps that own this event.
                try updateDatestamps(
                    with: calendarEvent.startDate,
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
        with date: Date,
        datestamps: inout Set<String>,
        plannerCache: inout [String: DateInRegion],
        settings: PlannerSettings,
        homeRegion: Region
    ) throws {
        let possibleDatestamps = getChronologicalPossibleDatestamps(
            for: date
        )

        for datestamp in possibleDatestamps {
            if datestamps.contains(datestamp) {
                continue
            }

            // Use the cached start of day for this datestamp to determine if the planner owns this event.
            if let cachedPlannerStartOfDay = plannerCache[
                datestamp
            ] {
                if date.belongsTo(cachedPlannerStartOfDay) {
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

            if date.belongsTo(plannerStartOfDay) {
                datestamps.insert(datestamp)
            }
        }
    }

}
