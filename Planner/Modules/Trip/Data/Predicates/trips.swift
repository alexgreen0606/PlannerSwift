//
//  trips.swift
//  Planner
//
//  Created by Alex Green on 6/28/26.
//

import SwiftUI
import SwiftData

extension Trip {
    static func trips(
        onOrBefore datestamp: String
    ) -> Predicate<Trip> {
        #Predicate<Trip> {
            $0.lastDatestamp >= datestamp
        }
    }
    
    static func trips(
        matching ids: Set<PersistentIdentifier>
    ) -> Predicate<Trip> {
        #Predicate<Trip> {
            ids.contains($0.id)
        }
    }
}
