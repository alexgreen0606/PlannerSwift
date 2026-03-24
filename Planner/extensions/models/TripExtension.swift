//
//  TripExtension.swift
//  Planner
//
//  Created by Alex Green on 3/22/26.
//

import Foundation
import SwiftDate

// Clean

extension Trip {

    var sortedPlanners: [Planner] {
        self.planners.sorted { $0.datestamp < $1.datestamp }
    }

    var firstDatestamp: String? {
        sortedPlanners.first?.datestamp
    }

    var lastDatestamp: String? {
        sortedPlanners.last?.datestamp
    }

    var dateComponents: Set<DateComponents> {
        Set(
            self.planners.compactMap { $0.datestamp.dateComponents }
        )
    }

    func plannerTransitionId(for datestamp: String) -> String {
        "\(datestamp)_\(String(describing: id))"
    }

}
