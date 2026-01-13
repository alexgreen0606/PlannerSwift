//
//  PreviewCalendarEventList.swift
//  Planner
//
//  Created by Alex Green on 1/13/26.
//

import EventKit
import SwiftUI

struct PreviewCalendarEventListView: View {
    let events: [EKEvent]
    let iconMap: [String: String]

    var body: some View {
        if !events.isEmpty {
            VStack(alignment: .leading, spacing: 0) {
                ForEach(events, id: \.eventIdentifier) { event in
                    HStack(spacing: 4) {
                        Image(
                            systemName: iconMap[
                                event.calendar.calendarIdentifier
                            ]
                            ?? event.calendar.iconName
                        )
                        .resizable()
                        .scaledToFit()
                        .frame(width: 14, height: 14)
                        .foregroundStyle(Color(event.calendar.cgColor))
                        
                        Text(event.title)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color(event.calendar.cgColor))
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .frame(height: UIConstants.chipHeight)
                }
            }
        }
    }
}
