//
//  String+DatestampConversions.swift
//  Planner
//
//  Created by Alex Green on 5/14/26.
//

import Foundation
import SwiftDate
import SwiftData

extension String {
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
    
    var date: Date? {
        DatestampFormatter.parseDatestamp(self)
    }

    func startOfDay(in region: Region) -> DateInRegion? {
        guard
            let result = toDate("yyyy-MM-dd", region: region)?
                .dateAtStartOf(.day)
        else {
            return nil
        }

        return result
    }
}
