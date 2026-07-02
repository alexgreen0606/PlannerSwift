//
//  PlannerSearchQuery.swift
//  Planner
//
//  Created by Alex Green on 3/16/26.
//

import Foundation
import Fuse
import SwiftDate

struct PlannerSearchQuery: Equatable {
    var text: String
    var calendarIds: Set<String>
    var past: Bool

    // Helper Variables for filtering
    let todayStartOfDay: DateInRegion
    let fuse: Fuse

    static func == (
        lhs: PlannerSearchQuery,
        rhs: PlannerSearchQuery
    ) -> Bool {
        lhs.text == rhs.text && lhs.calendarIds == rhs.calendarIds
            && lhs.past == rhs.past
    }

    // MARK: - Helpers

    var timeFrameLabel: String {
        switch past {
        case true: return "past"
        case false: return "future"
        }
    }

    static let fuzzyThreshold: Double = 0.25

    var isFiltering: Bool {
        !text.isEmpty || !calendarIds.isEmpty
    }

    func containsDate(_ date: Date) -> Bool {
        if past && date >= todayStartOfDay.date {
            // Exclude. Date is too new.
            return false
        }

        if !past && date < todayStartOfDay.date {
            // Exclude. Date is too old.
            return false
        }

        return true
    }

    func containsDateRange(startDate: Date, endDate: Date)
        -> Bool
    {
        if past && startDate >= todayStartOfDay.date {
            // Exclude. Range is too new.
            return false
        }

        if !past && endDate < todayStartOfDay.date {
            // Exclude. Range is too old.
            return false
        }

        return true
    }

    func containsDatestamp(_ datestamp: String) -> Bool {
        if past && datestamp >= todayStartOfDay.datestamp {
            // Exclude. Datestamp is too new.
            return false
        }

        if !past && datestamp < todayStartOfDay.datestamp {
            // Exclude. Datestamp is too old.
            return false
        }

        return true
    }

    func containsDatestampRange(startDatestamp: String, endDatestamp: String)
        -> Bool
    {
        if past && startDatestamp >= todayStartOfDay.datestamp {
            // Exclude. Range is too new.
            return false
        }

        if !past && endDatestamp < todayStartOfDay.datestamp {
            // Exclude. Range is too old.
            return false
        }

        return true
    }

    func score(for text: String) -> Double?  // nil means the search text doesn't match the text
    {
        if let results = fuse.search(self.text, in: text),
            results.score <= Self.fuzzyThreshold
        {
            return 1 - results.score
        }

        return nil
    }

    func isCalendarHidden(calendarId: String) -> Bool {
        guard !calendarIds.isEmpty else {
            return false
        }

        return !calendarIds.contains(
            calendarId
        )
    }
}
