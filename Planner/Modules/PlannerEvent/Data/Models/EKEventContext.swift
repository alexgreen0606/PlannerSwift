//
//  EKEventContext.swift
//  Planner
//
//  Created by Alex Green on 6/10/26.
//

import Contacts
import EventKit
import SwiftData
import SwiftUI

@Model
class EKEventContext {

    var startDate: Date = Date.now
    var endDate: Date = Date.now
    var isAllDay: Bool = false

    var calendarItemExternalIdentifier: String = ""

    var calendarIdentifier: String = ""
    var calendarColorHex: String = UIColor.blue.cgColor.hexString
    var calendarAllowsContentModifications: Bool = true

    var birthdayContactIdentifier: String?
    var birthdayThumbnailData: Data?

    @Transient
    var ekEvent: EKEvent?

    @Transient
    var birthdayContact: CNContact?

    // MARK: Parent
    var plannerEvent: PlannerEvent?

    init(ekEvent: EKEvent, plannerEvent: PlannerEvent) {
        self.startDate = ekEvent.startDate
        self.endDate = ekEvent.endDate
        self.isAllDay = ekEvent.isAllDay

        self.calendarItemExternalIdentifier =
            ekEvent.calendarItemExternalIdentifier

        self.calendarIdentifier = ekEvent.calendar.calendarIdentifier
        self.calendarColorHex = ekEvent.calendar.cgColor.hexString
        self.calendarAllowsContentModifications =
            ekEvent.calendar.allowsContentModifications

        self.birthdayContactIdentifier = ekEvent.birthdayContactIdentifier

        self.ekEvent = ekEvent

        self.plannerEvent = plannerEvent
        plannerEvent.eKEventContext = self
    }
}
