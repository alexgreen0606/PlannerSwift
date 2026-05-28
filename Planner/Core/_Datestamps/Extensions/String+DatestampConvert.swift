//
//  String+DatestampConvert.swift
//  Planner
//
//  Created by Alex Green on 5/14/26.
//

import Foundation
import SwiftDate

extension String {
    var date: Date? {
        DatestampFormatter.date(from: self)
    }

    var dateComponents: DateComponents? {
        let parts = split(separator: "-")
        guard parts.count == 3,
              let year = Int(parts[0]),
              let month = Int(parts[1]),
              let day = Int(parts[2])
        else {
            return nil
        }

        return DateComponents(year: year, month: month, day: day)
    }

    func startOfDay(in region: Region) -> DateInRegion {
        toDate("yyyy-MM-dd", region: region)!.dateAtStartOf(.day)
    }
}
