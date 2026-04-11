//
//  Weekday.swift
//  Planner
//
//  Created by Alex Green on 3/30/26.
//

import SwiftUI

// Clean

enum Weekday: String, Codable, CaseIterable {
    case sunday
    case monday
    case tuesday
    case wednesday
    case thursday
    case friday
    case saturday

    var initial: String {
        String(self.rawValue.prefix(1)).uppercased()
    }

    var label: String {
        self.rawValue.capitalizedFirst
    }

    static func from(_ string: String) -> Weekday? {
        Weekday(rawValue: string.lowercased())
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
