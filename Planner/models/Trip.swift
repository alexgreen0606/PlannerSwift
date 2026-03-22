//
//  Trip.swift
//  Planner
//
//  Created by Alex Green on 3/21/26.
//

import SwiftData
import SwiftDate
import SwiftUI

// Clean

@Model
class Trip {

    var title: String = ""

    @Relationship(deleteRule: .nullify)
    var location: Location?

    var startDatestamp: String
    var endDatestamp: String

    var hideRoutines: Bool = true

    init() {
        let todaystamp = DateInRegion(Date(), region: .local).datestamp
        self.startDatestamp = todaystamp
        self.endDatestamp = todaystamp
    }
    
}
