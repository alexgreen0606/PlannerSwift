//
//  PlannerEventPositionChange.swift
//  Planner
//
//  Created by Alex Green on 2/1/26.
//

import SwiftData

enum PlannerEventPositionChange: Equatable {

    case planner(
        id: PersistentIdentifier,
        sortIndex: Double
    )

    case calendar(
        id: String,
        sortIndex: Double
    )

    case transfer(
        targetDatestamp: String
    )

    var plannerId: PersistentIdentifier? {
        switch self {
        case .planner(let id, _):
            return id
        case .calendar, .transfer:
            return nil
        }
    }

    var calendarId: String? {
        switch self {
        case .calendar(let id, _):
            return id
        case .planner, .transfer:
            return nil
        }
    }

    var targetSortIndex: Double? {
        switch self {
        case .planner(_, let sortIndex),
            .calendar(_, let sortIndex):
            return sortIndex
        case .transfer:
            return nil
        }
    }

    var isScrollable: Bool {
        switch self {
        case .planner, .calendar:
            return true
        case .transfer:
            return false
        }
    }
}
