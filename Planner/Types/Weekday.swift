//
//  Weekday.swift
//  Planner
//
//  Created by Alex Green on 3/30/26.
//

import SwiftUI

enum Weekday: String, Codable, CaseIterable {
    case Sunday
    case Monday
    case Tuesday
    case Wednesday
    case Thursday
    case Friday
    case Saturday

    var initial: String {
        String(self.rawValue.prefix(1))
    }

    var label: String {
        self.rawValue
    }

    static func forDatestamp(_ datestamp: String) -> Weekday? {
        Weekday(rawValue: datestamp.weekday)
    }

    func sortedEvents(in routineEvents: [RoutineEvent], reversed: Bool = false)
        -> [RoutineEvent]
    {
        routineEvents
            .filter { $0.sortDateMap[self] != nil }
            .sorted {
                if reversed {
                    $0.sortDateMap[self]! > $1.sortDateMap[self]!
                } else {
                    $0.sortDateMap[self]! < $1.sortDateMap[self]!
                }
            }
    }

}
