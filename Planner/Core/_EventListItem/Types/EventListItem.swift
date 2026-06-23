//
//  EventListItem.swift
//  Planner
//
//  Created by Alex Green on 4/6/26.
//

import Foundation

protocol EventListItem: EventDetails {
    /// Controlled by drag-and-drop.
    /// No relation to the event's time.
    var sortDate: Date { get set }
}
