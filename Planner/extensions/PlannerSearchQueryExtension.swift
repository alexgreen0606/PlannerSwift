//
//  PlannerSearchQuery.swift
//  Planner
//
//  Created by Alex Green on 3/17/26.
//

import Fuse
import SwiftDate
import SwiftUI

// Clean

extension PlannerSearchQuery {

    var isSearching: Bool {
        !self.text.isEmpty
            || !self.filteredCalendarIds.isEmpty
    }

    func containsDate(_ date: Date) -> Bool {
        if self.filterPast && date >= self.todayStartOfDay.date {
            // Exclude. Date is too new.
            return false
        }

        if !self.filterPast && date < self.todayStartOfDay.date {
            // Exclude. Date is too old.
            return false
        }

        return true
    }
    
    func containsDateRange(startDate: Date, endDate: Date)
        -> Bool
    {
        if self.filterPast && startDate >= self.todayStartOfDay.date {
            // Exclude. Range is too new.
            return false
        }

        if !self.filterPast && endDate < self.todayStartOfDay.date {
            // Exclude. Range is too old.
            return false
        }

        return true
    }

    func containsDatestamp(_ datestamp: String) -> Bool {
        if self.filterPast && datestamp >= self.todayStartOfDay.datestamp {
            // Exclude. Datestamp is too new.
            return false
        }

        if !self.filterPast && datestamp < self.todayStartOfDay.datestamp {
            // Exclude. Datestamp is too old.
            return false
        }

        return true
    }

    func containsDatestampRange(startDatestamp: String, endDatestamp: String)
        -> Bool
    {
        if self.filterPast && startDatestamp >= self.todayStartOfDay.datestamp {
            // Exclude. Range is too new.
            return false
        }

        if !self.filterPast && endDatestamp < self.todayStartOfDay.datestamp {
            // Exclude. Range is too old.
            return false
        }

        return true
    }

    func score(for text: String) -> Double?  // nil means the search text doesn't match the text
    {
        if let results = self.fuse.search(self.text, in: text),
            results.score <= FuseConstants.fuzzyThreshold
        {
            return 1 - results.score
        }

        return nil
    }

}
