//
//  CompletionTransitionDuration.swift
//  Planner
//
//  Created by Alex Green on 1/23/26.
//

import SwiftDate
import SwiftUI

// Clean

enum ToggleTransitionDuration: String, Codable, CaseIterable {
    case twoSeconds
    case threeSeconds
    case sixSeconds
    case instant

    static let title = "Toggle Transition"

    var label: String {
        switch self {
        case .instant: return "Instant"
        case .twoSeconds: return "2 Seconds"
        case .threeSeconds: return "3 Seconds"
        case .sixSeconds: return "6 Seconds"
        }
    }

    var seconds: Double {
        switch self {
        case .instant: return 0
        case .twoSeconds: return 2
        case .threeSeconds: return 3
        case .sixSeconds: return 6
        }
    }

    var duration: Duration { .seconds(seconds) }
}
