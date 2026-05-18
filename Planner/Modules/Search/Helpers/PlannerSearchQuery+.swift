//
//  PlannerSearchQuery+.swift
//  Planner
//
//  Created by Alex Green on 3/17/26.
//

import Fuse
import SwiftDate
import SwiftUI

// Clean

extension PlannerSearchQuery {
    static let fuzzyThreshold: Double = 0.35

    var isSearching: Bool {
        !text.isEmpty
            || !filteredCalendarIds.isEmpty
    }

    func containsDate(_ date: Date) -> Bool {
        if filterPast && date >= todayStartOfDay.date {
            // Exclude. Date is too new.
            return false
        }

        if !filterPast && date < todayStartOfDay.date {
            // Exclude. Date is too old.
            return false
        }

        return true
    }

    func containsDateRange(startDate: Date, endDate: Date)
        -> Bool
    {
        if filterPast && startDate >= todayStartOfDay.date {
            // Exclude. Range is too new.
            return false
        }

        if !filterPast && endDate < todayStartOfDay.date {
            // Exclude. Range is too old.
            return false
        }

        return true
    }

    func containsDatestamp(_ datestamp: String) -> Bool {
        if filterPast && datestamp >= todayStartOfDay.datestamp {
            // Exclude. Datestamp is too new.
            return false
        }

        if !filterPast && datestamp < todayStartOfDay.datestamp {
            // Exclude. Datestamp is too old.
            return false
        }

        return true
    }

    func containsDatestampRange(startDatestamp: String, endDatestamp: String)
        -> Bool
    {
        if filterPast && startDatestamp >= todayStartOfDay.datestamp {
            // Exclude. Range is too new.
            return false
        }

        if !filterPast && endDatestamp < todayStartOfDay.datestamp {
            // Exclude. Range is too old.
            return false
        }

        return true
    }

    func score(for text: String) -> Double? // nil means the search text doesn't match the text
    {
        if let results = fuse.search(self.text, in: text),
           results.score <= Self.fuzzyThreshold
        {
            return 1 - results.score
        }

        return nil
    }
}
