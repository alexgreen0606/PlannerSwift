//
//  PlannerCoverContext.swift
//  Planner
//
//  Created by Alex Green on 5/17/26.
//

struct PlannerCoverContext: Identifiable, Equatable {
    let datestamp: String
    let transitionId: String?

    init(datestamp: String, transitionId: String? = nil) {
        self.datestamp = datestamp
        self.transitionId = transitionId
    }

    var id: String {
        transitionId ?? datestamp
    }
}
