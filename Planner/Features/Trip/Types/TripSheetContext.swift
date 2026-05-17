//
//  TripSheetContext.swift
//  Planner
//
//  Created by Alex Green on 5/15/26.
//

struct TripSheetContext: Identifiable {
    var trip: Trip?

    var id: String {
        if let trip {
            return "\(trip.id)"
        }

        return "FALLBACK_NEW_SHEET"
    }
}
