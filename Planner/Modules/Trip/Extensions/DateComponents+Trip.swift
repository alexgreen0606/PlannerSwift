//
//  DateComponents+Trip.swift
//  Planner
//
//  Created by Alex Green on 5/15/26.
//

import SwiftUI

extension DateComponents {
    var datestamp: String? {
        guard
            let year = year,
            let month = month,
            let day = day
        else { return nil }

        return String(
            format: "%04d-%02d-%02d",
            year,
            month,
            day
        )
    }
}
