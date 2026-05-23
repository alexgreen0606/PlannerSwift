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
    let plannerDay: DateInRegion
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

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var plannerEngine: ListEngine<PlannerEvent>
    @EnvironmentObject private var locationService: LocationService

    private var emptyPendingEventsLabel: String {
        "No \(!sortedCompletePlannerEvents.isEmpty && showCompleted ? "more " : "")plans"
    }

    // MARK: - Body

    var body: some View {
        SortableListView(
            uncheckedItems: sortedPendingPlannerEvents,
            checkedItems: sortedCompletePlannerEvents,
            rowId: eventId,
            showChecked: showCompleted,
            checkedHeader: "Completed Events",
            emptyUncheckedLabel: emptyPendingEventsLabel,
            emptyCheckedLabel: "No completed events",
            tint: eventTint,
            scrollProxy: scrollProxy,
            createItem: createEvent,
            deleteItem: { event in
                modelContext.deletePlannerEvents(
                    [event],
                    in: planner,
                    ekEventStore: calendarStore.ekEventStore
                )
            },
            moveItem: moveUncheckedEvent,
            floatingInfo: chipSpread,
            namespace: namespace,
            toolbarSystemImageNames: ["rectangle.and.pencil.and.ellipsis"],
            onToolbarTap: handleToolbarTap,
            leftAdornment: calendarAdornment,
            rightAdornment: timeAdornment,
            bottomAdornment: locationAdornment,
            handleTitleChange: handleEventTitleChange
        )
    }

    // MARK: - View Builders

    private var chipSpread: some View {
        PlannerChipSpreadView(
            showLocationSheet: $showLocationSheet,
            planner: planner,
            plannerDay: plannerDay,
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
        }
    }

    private func timeAdornment(event: PlannerEvent) -> some View {
        event.timeAdornment(
            in: plannerDay.region,
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

    private func openPlannerEventSheet(_ event: PlannerEvent) {
        if plannerEngine.isSelectMode || event.isCompleted {
            plannerEngine.toggleItem(event)
            return
        }

        plannerEngine.protectedId = event.stableId
        plannerEngine.focusedId = nil
        eventSheetContext =
            EventSheetContext(
                plannerEvent: event,
                calendarEvent: nil
            )
    }

    private func moveUncheckedEvent(from: Int, to: Int) {
        modelContext.movePlannerEvent(
            from: from,
            to: to,
            plannerDay: plannerDay,
            // TODO: need to consider the sort ID based on ALL events
            sortedEvents: sortedPendingPlannerEvents
        )
    }

    private func handleEventTitleChange(event: PlannerEvent) {
        modelContext.handlePlannerEventTitleChange(
            event,
            in: planner,
            plannerDay: plannerDay,
            eventKitStore: calendarStore.ekEventStore,
            defaultLocation: plannerLocation
        )
    }

    private func handleToolbarTap(icon _: String, event: PlannerEvent) {
        openPlannerEventSheet(event)
    }

    private func eventTint(event: PlannerEvent) -> Color {
        event.tint(accentColor: accentColor)
    }

    private func eventId(event: PlannerEvent) -> String {
        "\(event.stableId)_\(event.location?.name ?? "NO_LOCATION")"
    }
}
