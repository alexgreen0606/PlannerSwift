//
//  PlannerItemCalendarAdornment.swift
//  Planner
//
//  Created by Alex Green on 11/23/26.
//

import EventKit
import SwiftUI

struct PlannerItemCalendarAdornmentView: View {
    let item: PlannerItem
    let settings: Settings

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    // MARK: - Body

    var body: some View {
        if let ekEvent = item.ekEvent {
            Image(
                systemName: settings.calendarIconMap[
                    ekEvent.calendar.calendarIdentifier
                ] ?? "calendar"
            )
            .imageScale(.small)
            .foregroundStyle(
                ekEvent.calendar.cgColor.map { Color(cgColor: $0) }
                    ?? accentColor.swiftUiColor
            )
        }
    }
}
