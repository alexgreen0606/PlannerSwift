//
//  DeletePlannerDelay.swift
//  Planner
//
//  Created by Alex Green on 1/20/26.
//

enum DeletePlansDelay: String, Codable, CaseIterable {
    case oneMonth
    case threeMonths
    case sixMonths
    case never

    var label: String {
        switch self {
        case .oneMonth:
            return "After 1 Month"
        case .threeMonths:
            return "After 3 Months"
        case .sixMonths:
            return "After 6 Months"
        case .never:
            return "Never"
        }
    }
}
