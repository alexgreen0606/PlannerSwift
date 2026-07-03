//
//  SearchQuery.swift
//  Planner
//
//  Created by Alex Green on 3/16/26.
//

import Foundation
import Fuse
import SwiftDate

struct SearchQuery: Equatable {
    var text: String
    var calendarIds: Set<String>
    var past: Bool

    // Helper Variables for filtering
    let todayStartOfDay: DateInRegion
    let fuse: Fuse

    static func == (
        lhs: SearchQuery,
        rhs: SearchQuery
    ) -> Bool {
        lhs.text == rhs.text
            && lhs.calendarIds == rhs.calendarIds
            && lhs.past == rhs.past
    }

    private static let FUZZY_THRESHOLD: Double = 0.25

    var isFiltering: Bool {
        !text.isEmpty || !calendarIds.isEmpty
    }

    var startDate: Date {
        if past {
            return (DateInRegion() - 2.years).date
        }

        return DateInRegion().date
    }

    var endDate: Date {
        if past {
            return DateInRegion().date
        }

        return (DateInRegion() + 2.years).date
    }

    var timeFrameLabel: String {
        switch past {
        case true: return "past"
        case false: return "future"
        }
    }

    func score(for text: String)
        -> /// nil means the text doesn't match the search text
        Double?
    {
        if let results = fuse.search(self.text, in: text),
            results.score <= Self.FUZZY_THRESHOLD
        {
            return 1 - results.score
        }

        return nil
    }

    func containsDate(_ date: Date) -> Bool {
        if past && date >= todayStartOfDay.date {
            // Filtering past and date is in the future or present. Exclude.
            return false
        }

        if !past && date < todayStartOfDay.date {
            // Filtering present or future and date is in the past. Exclude.
            return false
        }

        return true
    }

    func containsDatestamp(_ datestamp: String) -> Bool {
        if past && datestamp >= todayStartOfDay.datestamp {
            // Filtering past and datestamp is in the future or present. Exclude.
            return false
        }

        if !past && datestamp < todayStartOfDay.datestamp {
            // Filtering present or future and datestamp is in the past. Exclude.
            return false
        }

        return true
    }

    func containsDateRange(startDate: Date, endDate: Date)
        -> Bool
    {
        if past && startDate >= todayStartOfDay.date {
            // Filtering past and range is fully in the future or present. Exclude.
            return false
        }

        if !past && endDate < todayStartOfDay.date {
            // Filtering present or future and range is fully in the past. Exclude.
            return false
        }

        return true
    }

    func containsDatestampRange(startDatestamp: String, endDatestamp: String)
        -> Bool
    {
        if past && startDatestamp >= todayStartOfDay.datestamp {
            // Filtering past and range is fully in the future or present. Exclude.
            return false
        }

        if !past && endDatestamp < todayStartOfDay.datestamp {
            // Filtering present or future and range is fully in the past. Exclude.
            return false
        }

        return true
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
