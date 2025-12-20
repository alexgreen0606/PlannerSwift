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

enum EventEditConfig: Identifiable {
    case edit(EKEvent)
    case view(EKEvent)

    var id: String {
        switch self {
        case .edit(let event):
            String(describing: event.eventIdentifier)
        case .view(let event):
            String(describing: event.eventIdentifier)
        }
    }
}

struct PlannerChipSpreadView: View {
    let datestamp: String
    let events: [EKEvent]
    let showCountdown: Bool

    @State private var editConfig: EventEditConfig?
    @State var calendarEventStore = CalendarEventStore.shared
    
    @AppStorage("themeColor") var themeColor: ThemeColorOption = ThemeColorOption.blue

    @Namespace private var nameSpace
    
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
                    iconName: "calendar",
                    color: Color(event.calendar.cgColor)
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    if event.calendar.allowsContentModifications {
                        editConfig = .edit(event)
                    } else {
                        editConfig = .view(event)
                    }
                }
                .matchedTransitionSource(
                    id: String(describing: event.eventIdentifier),
                    in: nameSpace
                )
            }
        }
        .sheet(item: $editConfig) { destination in
            switch destination {
            case .edit(let event):
                EditCalendarEventView(
                    event: event,
                    eventStore: calendarEventStore.ekEventStore
                ) { action, updatedEvent in
                    calendarEventStore.refresh()
                    editConfig = nil
                }
                .tint(themeColor.swiftUIColor)
                .ignoresSafeArea()
                .navigationTransition(
                    .zoom(
                        sourceID: String(describing: event.eventIdentifier),
                        in: nameSpace
                    )
                )
                
            case .view(let event):
                    ViewCalendarEventView(event: event)
                    .tint(themeColor.swiftUIColor)
                    .presentationDetents([.height(340)])
                    .ignoresSafeArea()
                    .navigationTransition(
                        .zoom(
                            sourceID: String(describing: event.eventIdentifier),
                            in: nameSpace
                        )
                    )
                }
            }
    }
}
