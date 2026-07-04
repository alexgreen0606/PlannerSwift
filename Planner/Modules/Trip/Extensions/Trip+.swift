//
//  Trip+.swift
//  Planner
//
//  Created by Alex Green on 3/22/26.
//

import Foundation
import Fuse
import SwiftUI

extension Trip {
    var safePlanners: [Planner] {
        planners ?? []
    }
    
    var transitionId: String {
        "\(String(describing: id))"
    }

    func transitionId(for datestamp: String) -> String {
        "\(datestamp)_\(transitionId)"
    }

    var sortedPlanners: [Planner] {
        safePlanners.sorted { $0.datestamp < $1.datestamp }
    }

    var dateComponents: Set<DateComponents> {
        Set(
            safePlanners.compactMap { $0.datestamp.dateComponents }
        )
    }

    func day(of datestamp: String) -> CGFloat {
        guard
            let index = sortedPlanners.firstIndex(where: {
                $0.datestamp == datestamp
            })
        else {
            return 0.0
        }

        return Double(index) + 1.0
    }

    func dateRangeLabel(todaystamp: String) -> String {
        tripDateRangeLabel(
            firstDatestamp: firstDatestamp,
            lastDatestamp: lastDatestamp,
            todaystamp: todaystamp,
            referenceYear: firstDatestamp.year
        )
    }
}
