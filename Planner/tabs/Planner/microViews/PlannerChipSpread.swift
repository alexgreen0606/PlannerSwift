//
//  PlannerChipSpreadView.swift
//  Planner
//
//  Created by Alex Green on 12/17/25.
//

import EventKit
import SwiftDate
import SwiftUI
import WrappingHStack

struct PlannerChipSpreadView: View {
    let datestamp: String
    let events: [EKEvent]
    let showCountdown: Bool
    var chipAnimation: Namespace.ID
    let openCalendarEvent: (EKEvent) -> Void
    
    @AppStorage("themeColor") var themeColor: ThemeColorOption = ThemeColorOption.blue
    
    @State var calendarEventStore = CalendarEventStore.shared
    
    var daysUntil: String? {
        let date = datestamp.date
        return date?.daysUntil
    }

    var body: some View {
        WrappingHStack(alignment: .leading) {
            if showCountdown, daysUntil != nil {
                PlannerChipView(
                    title: daysUntil!,
                    iconName: nil,
                    color: Color(uiColor: .label)
                )
            }
            ForEach(events, id: \.eventIdentifier) { event in
                PlannerChipView(
                    title: event.title,
                    iconName: event.calendar.iconName,
                    color: Color(event.calendar.cgColor)
                )
                .contentShape(Rectangle())
                .onTapGesture{
                    openCalendarEvent(event)
                }
                .matchedTransitionSource(
                    id: String(describing: event.eventIdentifier),
                    in: chipAnimation
                )
            }
        }
    }
}
