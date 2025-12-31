//
//  PlannerEvent.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import EventKit
import Foundation
import SwiftData

@available(iOS 26.0, *)
@Model
class PlannerEvent: ListItem {
    var date: Date?

    @Relationship(inverse: \Planner.events)
    var planner: Planner?

    @Transient
    var calendarEvent: EKEvent? = nil

    init(
        sortIndex: Double,
        planner: Planner? = nil,
        calendarEvent: EKEvent? = nil
    ) {
        super.init(sortIndex: sortIndex)

        self.calendarEvent = calendarEvent
        self.title = calendarEvent?.title ?? ""
        date = calendarEvent?.startDate  // TODO: use end date if needed (MULTI_DAY)

        planner?.events.append(self)
    }
}
