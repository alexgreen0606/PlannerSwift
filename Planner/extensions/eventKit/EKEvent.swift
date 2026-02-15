//
//  EKEvent.swift
//  Planner
//
//  Created by Alex Green on 12/27/25.
//

import EventKit
import SwiftDate
import SwiftUI

extension EKEvent {
    
    var transitionId: String {
        "\(String(describing: self.eventIdentifier))"
    }
    
    @ViewBuilder
    func timeValueView(
        in region: Region,
        openSheet: (() -> Void)?
    ) -> some View {

        // TODO: determine if start or end date

        TimeValue(
            day: DateInRegion(self.startDate, region: region),
            disabled: false,
            color: Color(self.calendar.cgColor)
        ) {
            openSheet?()
        }
        
    }
    
}
