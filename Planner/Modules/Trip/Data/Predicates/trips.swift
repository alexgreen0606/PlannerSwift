//
//  trips.swift
//  Planner
//
//  Created by Alex Green on 6/28/26.
//

import SwiftUI

extension Trip {
    static func trips(
        beforeOrOn datestamp: String
    ) -> Predicate<Trip> {
        #Predicate<Trip> {
            $0.lastDatestamp >= datestamp
        }
    }
}
