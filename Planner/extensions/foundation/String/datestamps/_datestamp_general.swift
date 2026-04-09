//
//  _datestamp_general.swift
//  Planner
//
//  Created by Alex Green on 4/9/26.
//

import Foundation
import SwiftDate

// Clean

extension String {

    var calendarSymbolName: String {
        let dd = self.suffix(2)

        guard let day = Int(dd), (1...31).contains(day) else {
            return "note"
        }

        return "\(day).calendar"
    }

    func startOfDay(in region: Region) -> DateInRegion? {
        guard
            let result = self.toDate("yyyy-MM-dd", region: region)?
                .dateAtStartOf(.day)
        else {
            assertionFailure(
                "ERROR String: Could not create DateInRegion from \(self)"
            )
            return nil
        }
        return result
    }

    var dateComponents: DateComponents? {
        let parts = self.split(separator: "-")
        guard parts.count == 3,
            let year = Int(parts[0]),
            let month = Int(parts[1]),
            let day = Int(parts[2])
        else {
            return nil
        }

        return DateComponents(year: year, month: month, day: day)
    }

}
