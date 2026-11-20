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

    private static let FUZZY_THRESHOLD: Double = 0.25

    private static let fuse = Fuse()

    static func == (
        lhs: PlannerSearchQuery,
        rhs: PlannerSearchQuery
    ) -> Bool {
        lhs.text == rhs.text
            && lhs.calendarIds == rhs.calendarIds
    }

    var isDefault: Bool {
        text.isEmpty && calendarIds.isEmpty
    }

    var isSearchingText: Bool {
        return !text.trimmed.isEmpty
    }

    var filterCount: Int? {
        var count = 0

        count += calendarIds.count

        if count > 0 {
            return count
        }

        return nil
    }

    func score(for text: String)
        -> /// nil means the text doesn't match the search text
        Double?
    {
        if let results = Self.fuse.search(self.text, in: text),
            results.score <= Self.FUZZY_THRESHOLD
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
