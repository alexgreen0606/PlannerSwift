//
//  EventListItem.swift
//  Planner
//
//  Created by Alex Green on 4/6/26.
//

import Foundation

protocol EventListItem: ListItem {
    var time: Date? { get set }

    /// Controlled by drag-and-drop.
    /// No relation to the event's time.
    var sortDate: Date { get set }
}
