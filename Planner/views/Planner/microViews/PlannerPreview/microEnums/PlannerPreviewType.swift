//
//  PlannerPreviewType.swift
//  Planner
//
//  Created by Alex Green on 3/11/26.
//

enum PlannerPreviewType {
    case planner
    case search

    // TODO: need to make this more clear once trips are added
    var isThisWeek: Bool {
        self == .planner
    }
}
