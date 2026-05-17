//
//  DraftTrip.swift
//  Planner
//
//  Created by Alex Green on 3/21/26.
//

import SwiftUI

struct DraftTrip {
    var title: String = ""
    var location: Location? = nil
    var excludeRoutines: Bool = true
    var dateComponents: Set<DateComponents> = []

    var datestamps: [String] {
        dateComponents.compactMap { $0.datestamp }
    }

    func dateRangeLabel(todaystamp: String) -> String? {
        let sortedDatestamps = datestamps.sorted()

        guard let firstDatestamp = sortedDatestamps.first,
              let lastDatestamp = sortedDatestamps.last
        else {
            return nil
        }

        return buildDateRangeLabel(
            firstDatestamp: firstDatestamp,
            lastDatestamp: lastDatestamp,
            todaystamp: todaystamp
        )
    }
}
