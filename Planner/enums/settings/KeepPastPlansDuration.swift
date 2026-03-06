//
//  KeepPastPlansDuration.swift
//  Planner
//
//  Created by Alex Green on 1/20/26.
//

import SwiftDate
import SwiftUI

// Clean

enum KeepPastPlansDuration: String, Codable, CaseIterable {
    case oneMonth
    case threeMonths
    case sixMonths
    case forever

    static var title: String {
        "Keep Past Plans"
    }

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
        guard let monthOffset = monthOffset else { return .distantPast }

        return DateInRegion(Date(), region: .local)
            .dateByAdding(monthOffset, .month)
            .date
    }

    // MARK: - Helper Variables

    private var monthOffset: Int? {
        switch self {
        case .oneMonth:
            return -1
        case .threeMonths:
            return -3
        case .sixMonths:
            return -6
        case .forever: return nil
        }
    }

}
