//
//  PlannerListContext.swift
//  Planner
//
//  Created by Alex Green on 6/29/26.
//

struct PlannerListContext {
    let structuredDatestamps: StructuredDatestampsContext
    let query: PlannerSearchQuery?

    init(
        structuredDatestamps: StructuredDatestampsContext,
        query: PlannerSearchQuery? = nil
    ) {
        self.structuredDatestamps = structuredDatestamps
        self.query = query
    }
}
