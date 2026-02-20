//
//  PlannerEventPositionChange.swift
//  Planner
//
//  Created by Alex Green on 2/1/26.
//

import SwiftData
import SwiftUI

enum PlannerEventPositionChange: Equatable {

    case planner(
        id: PersistentIdentifier,
        sortDate: Date
    )

    case calendar(
        id: String,
        sortDate: Date
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

    var targetSortDate: Date? {
        switch self {
        case .planner(_, let sortDate),
            .calendar(_, let sortDate):
            return sortDate
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
