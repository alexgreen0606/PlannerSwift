//
//  Homepage.swift
//  Planner
//
//  Created by Alex Green on 9/22/26.
//

import SwiftUI

enum Homepage: String, Codable, CaseIterable {
    case thisWeek
    case today

    static let title = "Homepage"

    var label: String {
        switch self {
        case .thisWeek: return "This Week"
        case .today: return "Today"
        }
    }
}
