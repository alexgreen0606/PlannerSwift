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

    @State private var editConfig: EventEditConfig?
    @EnvironmentObject private var calendarStore: CalendarEventStore
    
    @AppStorage("themeColor") var themeColor: ColorOption = ColorOption.green

    @Namespace private var nameSpace

    var body: some View {
        WrappingHStack(alignment: .leading) {
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
                    eventStore: calendarStore.ekEventStore
                ) { action, updatedEvent in
                    calendarStore.refresh()
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
                    .presentationDetents([.height(280)])
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
