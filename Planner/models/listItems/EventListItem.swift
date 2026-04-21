//
//  EventListItem.swift
//  Planner
//
//  Created by Alex Green on 4/6/26.
//

import EventKit
import Foundation
import SwiftData

// Clean

@available(iOS 26.0, *)
@Model
class EventListItem: ListItem {

    // Controlled by drag-and-drop.
    // May go out of sync with the date.
    var sortDate: Date = Date()

    init(sortDate: Date) {
        self.sortDate = sortDate
        super.init(sortIndex: 0)
    }
}
