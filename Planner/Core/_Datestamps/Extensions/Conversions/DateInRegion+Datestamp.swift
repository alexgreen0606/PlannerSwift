//
//  DateInRegion+Datestamp.swift
//  Planner
//
//  Created by Alex Green on 3/26/26.
//

import SwiftDate

extension DateInRegion {
    var datestamp: String { // Ex: 2000-06-06
        toFormat("yyyy-MM-dd")
    }
}
