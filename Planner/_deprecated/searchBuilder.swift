//
//  searchBuilder.swift
//  Planner
//
//  Created by Alex Green on 3/5/26.
//

//        let today = todaystampWatcher.todaystamp
//        let todayDate = today.toDate("yyyy-MM-dd", region: .local)?.date
//        let maxDate = todaystampWatcher.maxCalendarDate
//
//        // ------------------------------------------------------------------
//        // 1. Collect all datestamps that have events (all-day + single-day)
//        // ------------------------------------------------------------------
//        let eventDatestamps = Set(
//            calendarStore.allDayEventsByDatestamp.keys
//        ).union(
//            calendarStore.singleDayEventsByDatestamp.keys
//        )
//
//        // ------------------------------------------------------------------
//        // 2. Trim datestamps to the desired date range
//        // ------------------------------------------------------------------
//        let dateRangeFiltered: [(year: String, datestamp: String)] =
//            eventDatestamps.compactMap { datestamp in
//                guard
//                    let date = datestamp.toDate("yyyy-MM-dd", region: .local)?
//                        .date,
//                    let todayDate,
//                    date > todayDate,
//                    date < maxDate
//                else { return nil }
//
//                return (String(date.year), datestamp)
//            }
//
//        // ------------------------------------------------------------------
//        // 3. Filter events by:
//        //    a) calendar IDs (if provided)
//        //    b) checked status
//        //    c) search text in title (if provided)
//        //    Remove datestamps with zero remaining events
//        // ------------------------------------------------------------------
//        let filteredDatestamps = dateRangeFiltered.compactMap {
//            entry -> (year: String, datestamp: String)? in
//            let datestamp = entry.datestamp
//
//            // Combine all events for this datestamp
//            let events =
//                (calendarStore.allDayEventsByDatestamp[datestamp] ?? [])
//                + (calendarStore.singleDayEventsByDatestamp[datestamp] ?? [])
//
//            // Filter by calendar identifiers (skip if none selected)
//            let calendarFiltered =
//                filterCalendarIds.isEmpty
//                ? events
//                : events.filter {
//                    filterCalendarIds.contains($0.calendar.calendarIdentifier)
//                }
//
//            // Filter out checked events
//            let checkedFiltered =
//                settings == nil
//                ? calendarFiltered
//                : calendarFiltered.filter {
//                    !settings.checkedCalendarEventIds.contains(
//                        $0.calendarItemExternalIdentifier
//                    )
//                }
//
//            let trimmedSearchText = searchText.trimmingCharacters(
//                in: .whitespacesAndNewlines
//            )
//
//            // Filter by search text in title (skip if empty)
//            let searchFiltered =
//                trimmedSearchText.isEmpty
//                ? checkedFiltered
//                : checkedFiltered.filter {
//                    $0.title.localizedCaseInsensitiveContains(
//                        trimmedSearchText
//                    )
//                }
//
//            // Remove this datestamp entirely if no events remain
//            guard !searchFiltered.isEmpty else { return nil }
//
//            return entry
//        }
//
//        // ------------------------------------------------------------------
//        // 4. Group remaining datestamps by year
//        // ------------------------------------------------------------------
//        let grouped = Dictionary(grouping: filteredDatestamps, by: { $0.year })
//
//        // ------------------------------------------------------------------
//        // 5. Sort datestamps within each year
//        // ------------------------------------------------------------------
//        eventMap = grouped.mapValues { values in
//            values
//                .map { $0.datestamp }
//                .sorted()
//        }
//
//        scrollToTopTrigger = UUID()
