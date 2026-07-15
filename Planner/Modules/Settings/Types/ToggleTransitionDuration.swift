//
//  ToggleTransitionDuration.swift
//  Planner
//
//  Created by Alex Green on 1/23/26.
//

import SwiftDate
import SwiftUI

enum ToggleTransitionDuration: String, Codable, CaseIterable {
    case instant
    case oneSecond
    case twoSeconds
    case threeSeconds
    case sixSeconds

    static let title = "Toggle Transition"

    var label: String {
        switch self {
        case .instant: return "Instant"
        case .oneSecond: return "1 Second"
        case .twoSeconds: return "2 Seconds"
        case .threeSeconds: return "3 Seconds"
        case .sixSeconds: return "6 Seconds"
        }
    }

    var seconds: Double {
        switch self {
        case .instant: return 0
        case .oneSecond: return 1
        case .twoSeconds: return 2
        case .threeSeconds: return 3
        case .sixSeconds: return 6
        }
    }

    var duration: Duration {
        .seconds(seconds)
    }
}
