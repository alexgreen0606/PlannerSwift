//
//  DraftTrip.swift
//  Planner
//
//  Created by Alex Green on 3/21/26.
//

import SwiftUI

// Clean

struct DraftTrip {
    var title: String = ""
    var location: Location? = nil
    var hideRoutines: Bool = true
    var dateComponents: Set<DateComponents> = []

    var datestampBounds: (startDatestamp: String, endDatestamp: String)? {
        let calendar = Calendar.current

        let sortedDateComponents = dateComponents.sorted { lhs, rhs in
            guard let lhsDate = calendar.date(from: lhs),
                let rhsDate = calendar.date(from: rhs)
            else {
                return false
            }
            return lhsDate < rhsDate
        }

        guard let startDatestamp = sortedDateComponents.first?.datestamp,
            let endDatestamp = sortedDateComponents.last?.datestamp
        else {
            return nil
        }

        return (startDatestamp, endDatestamp)
    }
    
}
