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
    @Binding var eventSheetContext: PlannerEventSheetContext?
    let planner: Planner
    let startOfDay: DateInRegion
    let plannerLocation: Location?
    let sortedPlannerEvents: [PlannerEvent]
    let sortedPendingPlannerEvents: [PlannerEvent]
    let sortedCompletePlannerEvents: [PlannerEvent]
    let sortedEventChips: [PlannerEvent]
    let sortedBirthdayChips: [PlannerEvent]
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

    private var emptyPendingEventsLabel: LocalizedStringKey {
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
            sortedEventChips: sortedEventChips,
            sortedBirthdayChips: sortedBirthdayChips,
            settings: settings,
            namespace: namespace,
            openEventSheet: openPlannerEventSheet
        )
    }

    private func calendarAdornment(event: PlannerEvent) -> some View {
        PlannerEventCalendarAdornmentView(
            plannerEvent: event,
            settings: settings,
            openEventSheet: {
                openPlannerEventSheet(event)
            }
        )
    }

    private func timeAdornment(event: PlannerEvent) -> some View {
        PlannerEventTimeAdornmentView(
            plannerEvent: event,
            plannerRegion: startOfDay.region,
            openEventSheet: {
                openPlannerEventSheet(event)
            }
        )
    }

    private func locationAdornment(event: PlannerEvent) -> some View {
        PlannerEventLocationAdornmentView(
            plannerEvent: event,
            planner: planner,
            settings: settings,
            openEventSheet: {
                openPlannerEventSheet(event)
            }
        )
    }

    // MARK: - Functions

    private func moveUncheckedEvent(from: Int, to: Int) {
        modelContext.movePlannerEvent(
            initialIndex: from,
            targetIndex: to,
            sortedPendingPlannerEvents: sortedPendingPlannerEvents,
            sortedPlannerEvents: sortedPlannerEvents,
            startOfDay: startOfDay
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
