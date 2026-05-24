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
