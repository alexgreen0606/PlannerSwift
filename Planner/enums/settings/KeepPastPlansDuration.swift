//
//  KeepPastPlansDuration.swift
//  Planner
//
//  Created by Alex Green on 1/20/26.
//

import SwiftDate
import SwiftUI

enum KeepPastPlansDuration: String, Codable, CaseIterable {
    case oneMonth
    case threeMonths
    case sixMonths
    case forever

    var label: String {
        switch self {
        case .oneMonth:
            return "1 Month"
        case .threeMonths:
            return "3 Months"
        case .sixMonths:
            return "6 Months"
        case .forever:
            return "Forever"
        }
    }

    var cutoffDate: Date {

        var monthOffset: Int = 0
        
        switch self {
        case .oneMonth:
            monthOffset = 1
        case .threeMonths:
            monthOffset = 3
        case .sixMonths:
            monthOffset = 6
        case .forever: return .distantPast
        }

        return DateInRegion(Date(), region: .local)
            .dateByAdding(-monthOffset, .month)
            .date

    }
}
