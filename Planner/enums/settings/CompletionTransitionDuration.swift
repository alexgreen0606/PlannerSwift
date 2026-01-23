//
//  CompletionTransitionDuration.swift
//  Planner
//
//  Created by Alex Green on 1/23/26.
//

import SwiftDate
import SwiftUI

enum CompletionTransitionDuration: String, Codable, CaseIterable {
    case twoSeconds
    case threeSeconds
    case sixSeconds
    case instant

    var label: String {
        switch self {
        case .instant:
            return "Instant"
        case .twoSeconds:
            return "2 Seconds"
        case .threeSeconds:
            return "3 Seconds"
        case .sixSeconds:
            return "6 Seconds"
        }
    }

    var duration: Duration {
        switch self {
        case .twoSeconds:
            return .seconds(2)
        case .threeSeconds:
            return .seconds(3)
        case .sixSeconds:
            return .seconds(6)
        case .instant: return Duration.zero
        }
    }
}
