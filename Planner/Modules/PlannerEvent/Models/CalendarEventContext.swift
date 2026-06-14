//
//  CalendarEventContext.swift
//  Planner
//
//  Created by Alex Green on 6/10/26.
//

import Contacts
import EventKit
import SwiftData
import SwiftUI

@Model
class CalendarEventContext {
    var startDate: Date = Date.now
    var endDate: Date = Date.now
    var isAllDay: Bool = false

    var calendarItemExternalIdentifier: String = ""
    var calendarId: String = ""
    var calendarColorHex: String = UIColor.blue.cgColor.hexString
    var editable: Bool = true

    var birthdayContactIdentifier: String?
    var birthdayThumbnailData: Data?

    var plannerEvent: PlannerEvent?

    @Transient
    var ekEvent: EKEvent?

    @Transient
    var birthdayContact: CNContact?

    init(ekEvent: EKEvent) {
        self.startDate = ekEvent.startDate
        self.endDate = ekEvent.endDate
        self.isAllDay = ekEvent.isAllDay
        
        self.calendarItemExternalIdentifier =
            ekEvent.calendarItemExternalIdentifier
        self.calendarId = ekEvent.calendar.calendarIdentifier
        self.calendarColorHex = ekEvent.calendar.cgColor.hexString
        self.editable = ekEvent.calendar.allowsContentModifications
        
        self.birthdayContactIdentifier = ekEvent.birthdayContactIdentifier
        
        self.ekEvent = ekEvent
    }
}
