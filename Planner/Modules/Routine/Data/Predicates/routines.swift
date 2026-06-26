//
//  routines.swift
//  Planner
//
//  Created by Alex Green on 6/19/26.
//

import SwiftUI

extension Routine {
    static func routines(
        for weekdayRawValue: String
    ) -> Predicate<Routine> {
        #Predicate<Routine> {
            $0.weekdayRawValue == weekdayRawValue
        }
    }
    
    static func routines(
        for weekdays: Set<Weekday>
    ) -> Predicate<Routine> {
        let rawValueSet = Set(weekdays.map(\.rawValue))
        
        return #Predicate<Routine> {
            rawValueSet.contains($0.weekdayRawValue)
        }
    }
}
