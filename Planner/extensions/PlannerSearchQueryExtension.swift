//
//  PlannerSearchQuery.swift
//  Planner
//
//  Created by Alex Green on 3/17/26.
//

// Clean

extension PlannerSearchQuery {

    var isSearching: Bool {
        !self.text.isEmpty
            || !self.filteredCalendarIds.isEmpty
    }

}
