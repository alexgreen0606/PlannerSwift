//
//  planners.swift
//  Planner
//
//  Created by Alex Green on 6/28/26.
//

import SwiftUI

extension Planner {
    static func planners(
        datestamp: String
    ) -> Predicate<Planner> {
        #Predicate<Planner> {
            $0.datestamp == datestamp
        }
    }

    static func planners(
        datestamps: Set<String>
    ) -> Predicate<Planner> {
        #Predicate<Planner> {
            datestamps.contains($0.datestamp)
        }
    }

    static var plannersWithLocations: Predicate<Planner> =
        #Predicate<Planner> {
            $0.location != nil
        }
}
