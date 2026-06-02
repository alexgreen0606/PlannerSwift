//
//  PlannerEventCalendarAdornment.swift
//  Planner
//
//  Created by Alex Green on 6/1/26.
//

import EventKit
import SwiftUI

struct PlannerEventCalendarAdornmentView: View {
    private let plannerEvent: PlannerEvent
    private let settings: PlannerSettings
    private let openEventSheet: (() -> Void)?

    init(
        plannerEvent: PlannerEvent,
        settings: PlannerSettings,
        openEventSheet: (() -> Void)? = nil
    ) {
        self.plannerEvent = plannerEvent
        self.settings = settings
        self.openEventSheet = openEventSheet
    }

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    // MARK: - Body

    var body: some View {
        if let calendarEvent = plannerEvent.calendarEvent,
            let calendar = calendarEvent.calendar
        {
            Image(
                systemName:
                    calendar.systemImageName(settings: settings)
            )
            .foregroundStyle(calendar.color)
            .contentShape(Rectangle())
            .onTapGesture {
                openEventSheet?()
            }
        } else if plannerEvent.calendarItemExternalIdentifier != nil {
            // Temporary icon before the calendar event hydrates.
            Image(
                systemName: "calendar"
            )
            .foregroundStyle(accentColor.color)
        }
    }
}
