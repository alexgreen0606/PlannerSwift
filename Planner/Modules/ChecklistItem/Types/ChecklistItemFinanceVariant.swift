//
//  ChecklistItemFinanceVariant.swift
//  Planner
//
//  Created by Alex Green on 10/6/26.
//

import SwiftUI

enum ChecklistItemFinanceVariant: String, Codable, CaseIterable {
    case none
    case sum
    case progressUp
    case progressDown
    case compare

    static let title = "Finance"

    var label: String {
        switch self {
        case .progressUp:
            return "Progress Up"
        case .progressDown:
            return "Progress Down"
        case .compare, .sum, .none:
            return rawValue.capitalized
        }
    }
}
