//
//  KeepPastEventsDuration.swift
//  Planner
//
//  Created by Alex Green on 1/20/26.
//

import SwiftDate
import SwiftUI

enum KeepPastEventsDuration: String, Codable, CaseIterable {
    case oneMonth
    case threeMonths
    case sixMonths
    case forever

    static let title = "Keep Past Events"

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

    /// The farthest back date users can access in their calendar.
    var cutoffDate: Date {
        guard let monthOffset else { return .distantPast }

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
