//
//  DateComponents.swift
//  Planner
//
//  Created by Alex Green on 3/23/26.
//

import SwiftUI

// Clean

extension DateComponents {

    var datestamp: String? {
        guard
            let year = self.year,
            let month = self.month,
            let day = self.day
        else { return nil }

        return String(
            format: "%04d-%02d-%02d",
            year,
            month,
            day
        )
    }
    
}
