//
//  EKEvent.swift
//  Planner
//
//  Created by Alex Green on 12/27/25.
//

import EventKit
import SwiftUI

extension EKEvent {
    @ViewBuilder
    func timeValueView(
        for datestamp: String,
        openEventSheet: ((EKEvent) -> Void)?
    ) -> some View {

        // TODO: determine if start or end date

        TimeValue(
            date: self.startDate,
            datestamp: datestamp,
            disabled: false,
            color: Color(self.calendar.cgColor)
        ) {
            openEventSheet?(self)
        }
        
    }
}
