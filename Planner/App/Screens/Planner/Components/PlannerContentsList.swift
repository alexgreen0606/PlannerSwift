//
//  PlannerContentsList.swift
//  Planner
//
//  Created by Alex Green on 3/11/26.
//

import EventKit
import SwiftData
import SwiftDate
import SwiftUI
import WeatherKit

struct PlannerContentsListView: View {
    @Binding var showLocationSheet: Bool
    @Binding var eventSheetContext: EventSheetContext?
    let planner: Planner
    let startOfDay: DateInRegion
    let plannerLocation: Location?
    let sortedPlannerEvents: [PlannerEvent]
    let sortedPendingPlannerEvents: [PlannerEvent]
    let sortedCompletePlannerEvents: [PlannerEvent]
    let calendarDayData: CalendarDayData?
    let showCompleted: Bool
    let scrollProxy: ScrollViewProxy
    let settings: PlannerSettings
    let namespace: Namespace.ID
    let createEvent: (Int) -> Void
    let handleEventTitleChange: (PlannerEvent) -> Void
    let openPlannerEventSheet: (PlannerEvent) -> Void

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var calendarStore: CalendarService
    @EnvironmentObject private var plannerEngine: ListEngine<PlannerEvent>
    @EnvironmentObject private var locationService: LocationService

    private var emptyPendingEventsLabel: String {
        "No \(!sortedCompletePlannerEvents.isEmpty && showCompleted ? "more " : "")plans"
    }

    // MARK: - Body

    var body: some View {
        SortableTextfieldListView(
            sortedItems: sortedPlannerEvents,
            floatingInfo: chipSpread,
            createItem: createEvent,
            moveItem: moveUncheckedEvent,
            deleteItem: deleteEvent,
            handleTitleChange: handleEventTitleChange,
            sortedPendingItems: sortedPendingPlannerEvents,
            emptyPendingLabel: emptyPendingEventsLabel,
            sortedCompletedItems: sortedCompletePlannerEvents,
            showCompleted: showCompleted,
            completedHeader: "Completed Events",
            emptyCompletedLabel: "No completed events",
            rowId: eventId,
            tint: eventTint,
            leftAdornment: calendarAdornment,
            rightAdornment: timeAdornment,
            bottomAdornment: locationAdornment,
            scrollProxy: scrollProxy,
            namespace: namespace
        )
    }

    // MARK: - View Builders

    private var chipSpread: some View {
        PlannerChipSpreadView(
            showLocationSheet: $showLocationSheet,
            planner: planner,
            startOfDay: startOfDay,
            plannerLocation: plannerLocation,
            calendarDayData: calendarDayData,
            settings: settings,
            namespace: namespace,
            openCalendarEventSheet: { calEvent in
                eventSheetContext =
                    EventSheetContext(
                        plannerEvent: nil,
                        calendarEvent: calEvent
                    )
            }
        )
    }

    @ViewBuilder
    private func calendarAdornment(event: PlannerEvent) -> some View {
        if let calendarEvent = event.calendarEvent,
            let calendar = calendarEvent.calendar
        {
            Image(
                systemName:
                    calendar.systemImageName(settings: settings)
            )
            .foregroundStyle(calendar.color)
            .padding(.trailing, 4)
            .contentShape(Rectangle())
            .onTapGesture {
                openPlannerEventSheet(event)
            }
        } else if event.calendarItemExternalIdentifier != nil {
            // Temporary icon before the calendar events hydrate.
            Image(
                systemName: "calendar"
            )
            .foregroundStyle(accentColor.color)
            .padding(.trailing, 4)
        }
    }

    private func timeAdornment(event: PlannerEvent) -> some View {
        event.timeAdornment(
            in: startOfDay.region,
            accentColor: accentColor,
            openEventSheet: {
                openPlannerEventSheet(event)
            }
        )
    }

    private func locationAdornment(event: PlannerEvent) -> some View {
        event.locationAdornment(
            in: planner,
            settings: settings,
            deviceLocation: locationService.deviceLocation,
            accentColor: accentColor,
            openEventSheet: {
                openPlannerEventSheet(event)
            }
        )
    }

    // MARK: - Functions

    private func moveUncheckedEvent(from: Int, to: Int) {
        modelContext.movePlannerEvent(
            from: from,
            to: to,
            startOfDay: startOfDay,
            sortedPendingPlannerEvents: sortedPendingPlannerEvents,
            sortedPlannerEvents: sortedPlannerEvents
        )
    }

    private func deleteEvent(_ event: PlannerEvent) {
        modelContext.deletePlannerEvent(
            event,
            in: planner,
            ekEventStore: calendarStore.ekEventStore
        )
    }

    private func eventId(event: PlannerEvent) -> String {
        "\(event.stableId)_\(event.location?.name ?? "NO_LOCATION")"
    }

    private func eventTint(event: PlannerEvent) -> Color {
        event.tint(accentColor: accentColor)
    }
}
