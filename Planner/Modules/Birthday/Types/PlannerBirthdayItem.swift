//
//  PlannerBirthdayItem.swift
//  Planner
//
//  Created by Alex Green on 11/23/26.
//

import EventKit
import Foundation

/// A birthday calendar event paired with its contact's thumbnail.
struct PlannerBirthdayItem: Identifiable {
    let ekEvent: EKEvent
    let contactIdentifier: String
    let thumbnailData: Data?

    var id: String {
        "\(contactIdentifier)|\(ekEvent.occurrenceDate?.timeIntervalSince1970 ?? 0)"
    }

    var title: String {
        ekEvent.title ?? ""
    }
}
