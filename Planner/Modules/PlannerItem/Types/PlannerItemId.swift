//
//  PlannerItemId.swift
//  Planner
//
//  Created by Alex Green on 11/22/26.
//

import Foundation

/// A stable identity for any row rendered in a planner list.
enum PlannerItemID: Hashable {
    case plannerEvent(UUID)
    case ekEvent(EkEventIdentity)

    /// A string form of the identity. Used for transitions and drag-and-drop.
    var stringValue: String {
        switch self {
        case .plannerEvent(let uuid):
            return uuid.uuidString
        case .ekEvent(let identity):
            let occurrence =
                identity.recurrenceOccurrenceDate.map {
                    String($0.timeIntervalSince1970)
                } ?? ""

            return [
                identity.externalIdentifier,
                identity.calendarIdentifier,
                occurrence,
            ].joined(separator: "|")
        }
    }
}
