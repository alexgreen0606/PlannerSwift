//
//  PlannerChipList.swift
//  Planner
//
//  Created by Alex Green on 1/13/26.
//

import EventKit
import SwiftUI

// Clean

struct PlannerChipListView: View {
    let events: [EKEvent]
    let settings: PlannerSettings

    var body: some View {
        if !events.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(events, id: \.eventIdentifier, content: event)
            }
        }
    }

    // MARK: - View Builders

    private func event(_ event: EKEvent) -> some View {
        EventView(
            title: event.title,
            iconConfig: IconConfig(
                name: event.calendar.systemImageName(
                    settings: settings
                ),
                primaryColor: event.calendar.color
            ),
            color: event.calendar.color
        )
    }

}
