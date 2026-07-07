//
//  Weekday.swift
//  Planner
//
//  Created by Alex Green on 3/30/26.
//

import SwiftUI

enum Weekday: String, Codable, CaseIterable, Identifiable {
    case Sunday
    case Monday
    case Tuesday
    case Wednesday
    case Thursday
    case Friday
    case Saturday

    var id: String {
        rawValue
    }

    var index: Int {
        switch self {
        case .Sunday: return 0
        case .Monday: return 1
        case .Tuesday: return 2
        case .Wednesday: return 3
        case .Thursday: return 4
        case .Friday: return 5
        case .Saturday: return 6
        }
    }

    var initial: String {
        String(rawValue.prefix(1))
    }

    var label: String {
        rawValue
    }

    static func forDatestamp(_ datestamp: String) -> Weekday? {
        Weekday(rawValue: datestamp.weekday)
    }
}
