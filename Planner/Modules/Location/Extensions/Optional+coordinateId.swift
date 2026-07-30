//
//  Optional+coordinateId.swift
//  Planner
//
//  Created by Alex Green on 7/30/26.
//

import Foundation
import SwiftDate

extension Optional where Wrapped: Location {
    var coordinateId: String {
        guard let self else { return "CURRENT" }

        return self.coordinateId
    }
    
    var timeZoneId: String {
        guard let self else { return TimeZone.current.identifier }

        return self.timeZoneIdentifier
    }
}
