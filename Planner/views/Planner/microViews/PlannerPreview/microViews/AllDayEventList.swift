//
//  AllDayEventList.swift
//  Planner
//
//  Created by Alex Green on 1/13/26.
//

import EventKit
import SwiftUI

// Clean

struct AllDayEventListView: View {
    let events: [EKEvent]
    let settings: PlannerSettings

    var body: some View {
        if !events.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(events, id: \.eventIdentifier) { event in
                    HStack(spacing: 4) {
                        Image(
                            systemName: event.calendar.systemImageName(
                                settings: settings
                            )
                        )
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)

                        Text(event.title)
                            .font(.system(size: 14, weight: .medium))
                    }
                    .foregroundStyle(
                        event.calendar.color
                    )
                }
            }
        }
    }
}
