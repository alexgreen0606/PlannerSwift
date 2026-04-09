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

    func sortedEvents(in routineEvents: [RoutineEvent]) -> [RoutineEvent] {
        routineEvents
            .filter { $0.sortDateMap[self] != nil }
            .sorted {
                $0.sortDateMap[self]! < $1.sortDateMap[self]!
            }
    }

}
