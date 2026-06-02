//
//  EventListItem.swift
//  Planner
//
//  Created by Alex Green on 4/6/26.
//

import Foundation
import SwiftData

@available(iOS 26.0, *)
@Model
class EventListItem: ListItem {
    var time: Date?

    /// Controlled by drag-and-drop.
    /// No relation to the event's time.
    var sortDate: Date = Date()

    init(sortDate: Date, time: Date? = nil) {
        super.init()
        self.sortDate = sortDate
        self.time = time
    }
}
