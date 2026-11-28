//
//  PlannerTabMode.swift
//  Planner
//
//  Created by Alex Green on 11/27/26.
//

/// Which view the Planner tab is showing.
enum PlannerTabMode: String {
    case list
    case calendar

    var toggled: PlannerTabMode {
        switch self {
        case .list: .calendar
        case .calendar: .list
        }
    }

    /// The toggle shows the view it switches to.
    var toggleSystemImageName: String {
        switch self {
        case .list: "calendar"
        case .calendar: "text.line.magnify"
        }
    }
}
