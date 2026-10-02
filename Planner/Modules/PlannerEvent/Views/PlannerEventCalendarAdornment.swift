//
//  PlannerEventCalendarAdornment.swift
//  Planner
//
//  Created by Alex Green on 6/1/26.
//

import EventKit
import SwiftUI

struct PlannerEventCalendarAdornmentView: View {
    let plannerEvent: PlannerEvent
    let settings: Settings

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    // MARK: - Body

    var body: some View {
        if plannerEvent.eKEventContext != nil {
            Image(
                systemName: plannerEvent.calendarSystemImageName(
                    settings: settings
                )
            )
            .foregroundStyle(plannerEvent.tint(accentColor: accentColor))
        }
    }
}
