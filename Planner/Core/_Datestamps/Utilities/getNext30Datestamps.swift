//
//  getNext30Datestamps.swift
//  Planner
//
//  Created by Alex Green on 9/22/26.
//

import Foundation
import SwiftDate

func getNext30Datestamps() -> [String] {
    (0..<30).map { offset in
        DateInRegion(region: .local)
            .dateByAdding(offset, .day)
            .datestamp
    }
}
