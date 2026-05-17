//
//  PlannerCoverContext.swift
//  Planner
//
//  Created by Alex Green on 5/17/26.
//

struct PlannerCoverContext: Identifiable, Equatable {
    let datestamp: String
    let source: String?

    init(datestamp: String, source: String? = nil) {
        self.datestamp = datestamp
        self.source = source
    }

    var id: String {
        source ?? datestamp
    }
}
