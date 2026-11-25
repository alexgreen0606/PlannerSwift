//
//  CalendarEventForm.swift
//  Planner
//
//  Created by Alex Green on 11/22/26.
//

import EventKit
import EventKitUI
import SwiftData
import SwiftUI

/// The calendar half of the event form. Wraps `EditCalendarEventFormView` with a
/// "Remove from Calendar" button that jumps back to the Planner form.
/// When the original item is a Planner event, saving converts it into a calendar event.
struct CalendarEventFormView: View {
    let item: PlannerItem
    /// The calendar event being edited. For Planner events, this is a new, unsaved event.
    let ekEvent: EKEvent
    let planner: Planner
    let settings: Settings
    let removeFromCalendar: () -> Void

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.showToast) private var showToast
    @EnvironmentObject private var calendarService: CalendarService
    @EnvironmentObject private var todayService: TodayService
    @EnvironmentObject private var plannerCoverStore: PlannerCoverStore

    // MARK: - Body

    var body: some View {
        EditCalendarEventFormView(
            event: ekEvent,
            ekEventStore: calendarService.ekEventStore,
            onSave: handleCompletion
        )
        .tint(accentColor.swiftUiColor)
        .ignoresSafeArea()
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarSpacer(placement: .bottomBar)

            ToolbarItem(placement: .bottomBar) {
                Button(
                    "Remove from Calendar",
                    action: removeFromCalendar
                )
                .fontWeight(.medium)
            }
        }
        .interactiveDismissDisabled(true)
    }

    // MARK: - Functions

    private func handleCompletion(
        _ action: EKEventEditViewAction,
        _ savedEvent: EKEvent?
    ) {
        switch action {
        case .canceled:
            // Discard any draft values applied by the Planner form.
            ekEvent.rollback()

            // The source event had an empty title. Delete it.
            if item.title.trimmed.isEmpty {
                switch item.source {
                case .plannerEvent(let plannerEvent):
                    modelContext.deletePlannerEvent(plannerEvent)

                case .ekEvent(let ekEvent, let state):
                    _ = calendarService.ekEventStore.attemptDeleteEvent(ekEvent)

                    modelContext.deleteEkEventPlannerState(
                        for: ekEvent,
                        existing: state
                    )
                }

                modelContext.safeSave(
                    "CalendarEventForm handleCompletion canceled"
                )
            }

        case .deleted:
            switch item.source {
            case .plannerEvent(let plannerEvent):
                modelContext.deletePlannerEvent(plannerEvent)

            case .ekEvent(let ekEvent, let state):
                modelContext.deleteEkEventPlannerState(
                    for: ekEvent,
                    existing: state
                )
            }

            modelContext.safeSave("CalendarEventForm handleCompletion deleted")

        case .saved:
            if let savedEvent {
                handleSave(savedEvent)
            }

        @unknown default:
            break
        }

        // Note: Calendar changes are picked up by the EKEventStoreChanged notification.
        dismiss()
    }

    private func handleSave(_ savedEvent: EKEvent) {
        let destinationDatestamps = modelContext.calendarEventDatestamps(
            for: savedEvent,
            settings: settings
        )

        let staysInPlanner = destinationDatestamps.contains(planner.datestamp)

        switch item.source {
        case .plannerEvent(let plannerEvent):
            // MARK: Planner event moved into the calendar. Carry over its Planner-only data.

            let isCompleted = plannerEvent.isCompleted
            let sortDate = plannerEvent.sortDate

            modelContext.deletePlannerEvent(plannerEvent, skipSave: true)

            if !savedEvent.isAllDay {
                let state = modelContext.ensureEkEventPlannerState(
                    for: savedEvent,
                    sortDate: sortDate
                )

                state.sortDate = sortDate
                state.isCompleted = isCompleted
            }

        case .ekEvent(let sourceEkEvent, let state):
            // MARK: Existing calendar event edited.

            guard
                let state = state
                    ?? modelContext.getEkEventPlannerState(for: sourceEkEvent)
            else { break }

            if staysInPlanner {
                // Keep the state matched to the event if its occurrence date moved.
                state.recurrenceOccurrenceDate = savedEvent.occurrenceDate
            } else {
                // The event left this planner. Let it sort by its start time in its new planner.
                modelContext.delete(state)
            }
        }

        modelContext.safeSave("CalendarEventForm handleSave")

        showEventFormNotification(
            destinationDatestamps: destinationDatestamps,
            sourceDatestamp: planner.datestamp,
            todayService: todayService,
            plannerCoverStore: plannerCoverStore,
            showToast: showToast
        )
    }
}
