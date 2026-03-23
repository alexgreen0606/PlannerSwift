//
//  getDatestampBounds.swift
//  Planner
//
//  Created by Alex Green on 3/23/26.
//

import SwiftUI

// Clean

func getDatestampBounds(from componentsSet: Set<DateComponents>) -> (
    startDatestamp: String, endDatestamp: String
)? {
    let calendar = Calendar.current

    let sortedSelections = componentsSet.sorted { lhs, rhs in
        guard let lhsDate = calendar.date(from: lhs),
            let rhsDate = calendar.date(from: rhs)
        else {
            return false
        }
        return lhsDate < rhsDate
    }

    guard let startDatestamp = sortedSelections.first?.datestamp,
        let endDatestamp = sortedSelections.last?.datestamp
    else {
        return nil
    }

    return (startDatestamp, endDatestamp)
}
