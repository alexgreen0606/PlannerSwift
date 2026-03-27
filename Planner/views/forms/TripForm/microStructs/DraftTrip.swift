//
//  DraftTrip.swift
//  Planner
//
//  Created by Alex Green on 3/21/26.
//

import SwiftDate
import SwiftUI

// Clean

struct DraftTrip {
    var title: String = ""
    var location: Location? = nil
    var hideRoutines: Bool = true
    var dateComponents: Set<DateComponents> = []

    var datestamps: [String] {
        self.dateComponents.compactMap { $0.datestamp }
    }

    var dateRangeLabel: String? {
        let sortedDatestamps = datestamps.sorted()

        guard let firstDatestamp = sortedDatestamps.first,
            let lastDatestamp = sortedDatestamps.last,
            let firstDay = DateInRegion(firstDatestamp, region: .local),
            let lastDay = DateInRegion(lastDatestamp, region: .local)
        else {
            return nil
        }

        return buildDateRangeLabel(firstDay: firstDay, lastDay: lastDay)
    }

}
