//
//  EventChange.swift
//  Planner
//
//  Created by Alex Green on 2/1/26.
//

import SwiftData

enum EventChange {
    case planner(id: PersistentIdentifier)
    case calendar(id: String)
    case transfer
}
