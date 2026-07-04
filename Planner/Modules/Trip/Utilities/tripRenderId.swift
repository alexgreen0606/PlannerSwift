//
//  tripRenderId.swift
//  Planner
//
//  Created by Alex Green on 5/20/26.
//

import SwiftData

func tripRenderId(tripId: PersistentIdentifier, isExpanded: Bool) -> String {
    "\(String(describing: tripId))_\(isExpanded)"
}
