//
//  DateComponents+Datestamp.swift
//  Planner
//
//  Created by Alex Green on 5/20/26.
//

import SwiftUI

extension DateComponents {
    var datestamp: String? {
        guard
            let year,
            let month,
            let day
        else { return nil }

        return String(
            format: "%04d-%02d-%02d",
            year,
            month,
            day
        )
    }
}
