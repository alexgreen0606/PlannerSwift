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
    private let settings: Settings
    private let openEventSheet: (() -> Void)?

    init(
        plannerEvent: PlannerEvent,
        settings: Settings,
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
        if plannerEvent.eKEventContext != nil {
            Image(
                systemName: plannerEvent.calendarSystemImageName(
                    settings: settings
                )
            )
            .foregroundStyle(plannerEvent.tint(accentColor: accentColor))
            .contentShape(Rectangle())
            .onTapGesture {
                openEventSheet?()
            }
        }
    }
}
