//
//  Date.swift
//  Planner
//
//  Created by Alex Green on 12/10/25.
//

import SwiftUI
import SwiftDate

extension Date {
    var dayName: String { // Ex: Wednesday
        DateInRegion(self, region: .current).toFormat("EEEE", locale: Locale.current)
    }

    var longDate: String { // Ex: January 12, 2025
        DateInRegion(self, region: .current).toFormat("MMMM d, yyyy", locale: Locale.current)
    }
    
    var datestamp: String {
            let formatter = DateFormatter()
            formatter.calendar = Calendar(identifier: .gregorian)
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = .current
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: self)
        }
}
