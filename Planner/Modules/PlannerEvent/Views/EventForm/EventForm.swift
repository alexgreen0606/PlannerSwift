//
//  EventForm.swift
//  Planner
//
//  Created by Alex Green on 1/29/26.
//

import EventKit
import EventKitUI
import SwiftData
import SwiftDate
import SwiftUI

struct EventFormView: View {
    private let sourcePlanner: Planner?
    private let sourcePlannerEvent: PlannerEvent?
    private let sourceCalendarEvent: EKEvent?
    private let settings: PlannerSettings

    init(
        sourcePlanner: Planner? = nil,
        plannerEvent: PlannerEvent?,
        calendarEvent: EKEvent?,
        settings: PlannerSettings
    ) {
        sourcePlannerEvent = plannerEvent
        self.sourcePlanner = sourcePlanner
        sourceCalendarEvent = plannerEvent?.calendarEvent ?? calendarEvent
        self.settings = settings

        // ------------------------------------------------------------------
        // Build the draft event from the initial data.
        // ------------------------------------------------------------------

        var draftPlannerEvent = DraftPlannerEvent()

        if let calEvent = plannerEvent?.calendarEvent ?? calendarEvent {
            // ----------------------------------------------------------
            // Initialize the calendar event form.
            // Carry calendar event data over to the draft planner event.
            // ----------------------------------------------------------

            draftPlannerEvent.title = calEvent.title
            draftPlannerEvent.date = calEvent.startDate
            draftPlannerEvent.hasTime = true
            draftPlannerEvent.location = calEvent.location(
                storageEvent: sourcePlannerEvent
            )
            draftPlannerEvent.calendarEvent = calEvent

        } else if let plannerEvent {
            // ----------------------------------------------------------
            // Initialize the planner event form.
            // ----------------------------------------------------------

            draftPlannerEvent.title = plannerEvent.title
            draftPlannerEvent.hasTime = plannerEvent.time != nil
            draftPlannerEvent.location = plannerEvent.location

            if let time = plannerEvent.time {
                // Use the existing time for the event.
                draftPlannerEvent.date =
                    time.roundedDownNearest5Minutes
            }
        }

        if !draftPlannerEvent.hasTime {
            // Event has no time.
            // Initialize a user-friendly time.

            let now = DateInRegion(Date(), region: .local)

            let startDayInRegion = {
                if let sourcePlanner {
                    let startDayInRegion =
                        sourcePlanner.datestamp.startOfDay(
                            in: sourcePlanner.region(settings: settings)
                        ) ?? now

                    // This is a planner-specific form.
                    // Use the current hour on the day of the selected planner.
                    return startDayInRegion.dateBySet(
                        hour: now.hour,
                        min: 0,
                        secs: 0
                    ) ?? now
                }
                // Use the current hour (Create Event form only).
                return now
            }()

            // Round the time down to the start of the hour.
            draftPlannerEvent.date =
                startDayInRegion
                    .dateAtStartOf(.hour)
                    .date
        }

        self.draftPlannerEvent = draftPlannerEvent
    }

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.showToast) private var showToast
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var PlannerSyncStore: PlannerSyncService
    @EnvironmentObject private var LocationService: LocationService
    @EnvironmentObject private var PlannerCoverStore: PlannerCoverStore
    @EnvironmentObject private var TodaystampService: TodaystampService

    @State private var draftPlannerEvent: DraftPlannerEvent

    private var defaultLocation: Location? {
        sourcePlanner?.location(
            settings: settings,
            deviceLocation: LocationService.deviceLocation
        )
            ?? settings.homeLocation(
                deviceLocation: LocationService.deviceLocation
            )
    }

    var body: some View {
        ZStack {
            if let draftCalendarEvent = draftPlannerEvent.calendarEvent {
                calendarEventForm(for: draftCalendarEvent)
            } else {
                PlannerEventFormView(
                    draftPlannerEvent: $draftPlannerEvent,
                    settings: settings,
                    defaultLocation: defaultLocation,
                    sourceCalendarEvent: sourceCalendarEvent,
                    sourcePlannerEvent: sourcePlannerEvent,
                    sourcePlanner: sourcePlanner,
                    showNotification: showNotification
                )
            }
        }
        .tint(accentColor.color)
        .presentationBackground(.clear)
        .background(Color.clear)
        .presentationDetents(
            draftPlannerEvent.calendarEvent != nil
                && draftPlannerEvent.calendarEvent?.calendar
                .allowsContentModifications == false
                ? [.height(300)] : [.large]
        )

        // Ensure event location exists when hasTime is set to true.
        .onChange(of: draftPlannerEvent.hasTime) { _, _ in
            ensureLocationWhenTimed()
        }
    }

    // MARK: - View Builders

    @ViewBuilder
    private func calendarEventForm(for event: EKEvent) -> some View {
        if event.calendar.allowsContentModifications {
            EditCalendarEventFormView(
                event: event,
                ekEventStore: calendarStore.ekEventStore
            ) { action, event in
                guard action != .canceled else {
                    if let sourcePlannerEvent, let sourcePlanner,
                       sourcePlannerEvent.title.trimmingCharacters(
                           in: .whitespacesAndNewlines
                       ).isEmpty
                    {
                        // The source event had an empty title. Delete it.
                        modelContext.deletePlannerEvent(
                            sourcePlannerEvent,
                            in: sourcePlanner
                        )
                    }
                    dismiss()
                    return
                }

                saveCalendarEvent(event)
            }
            .tint(accentColor.color)
            .ignoresSafeArea()
            .overlay {
                VStack {
                    Spacer()
                    ActionButtonView(
                        label: "Remove From Calendar",
                        systemImage: "calendar.badge.minus",
                        onTap: removeEventFromCalendar
                    )
                }
            }
            .transition(.opacity)
        } else {
            ViewCalendarEventFormView(event: event)
                .ignoresSafeArea()
        }
    }

    // MARK: - Functions

    private func saveCalendarEvent(_ event: EKEvent?) {
        let destinationDatestamp = modelContext.handleCalendarEventChange(
            event,
            sourcePlanner: sourcePlanner,
            sourcePlannerEvent: sourcePlannerEvent,
            settings: settings
        )

        // Refresh calendar in case of recurring/all-day events.
        DispatchQueue.main.async(
            execute: PlannerSyncStore.rebuildCalendarData
        )

        dismiss()

        showNotification(
            sourceDatestamp: sourcePlanner?.datestamp,
            destinationDatestamp: destinationDatestamp,
            finalEkEvent: event
        )
    }

    private func showNotification(
        sourceDatestamp: String?,
        destinationDatestamp: String?,
        finalEkEvent _: EKEvent? = nil
    ) {
        var config: Toast?

        if sourcePlanner == nil {
            if let destinationDatestamp {
                config = Toast(
                    title:
                    "Successfully created event!",
                    subtitle:
                    "\(destinationDatestamp.dateWithYear) | \(destinationDatestamp.weekday)",
                    iconConfig: IconConfig(
                        name: "calendar.day.timeline.leading",
                        primaryColor: Color.label,
                        secondaryColor: Color.secondary
                    ),
                    variant: .tab,
                    action: {
                        PlannerCoverStore.context = PlannerCoverContext(
                            datestamp: destinationDatestamp
                        )
                    }
                )
            }
        } else if let destinationDatestamp {
            if destinationDatestamp != sourceDatestamp {
                let primaryColor =
                    destinationDatestamp > sourceDatestamp!
                        ? Color.secondary : Color.label
                let secondaryColor =
                    destinationDatestamp > sourceDatestamp!
                        ? Color.label : Color.secondary

                config = Toast(
                    title: "Successfully moved event!",
                    subtitle:
                    "\(destinationDatestamp.dateWithYear) | \(destinationDatestamp.weekday)",
                    iconConfig: IconConfig(
                        name: "arrow.left.arrow.right",
                        primaryColor: primaryColor,
                        secondaryColor: secondaryColor
                    ),
                    action: {
                        PlannerCoverStore.context = PlannerCoverContext(
                            datestamp: destinationDatestamp
                        )
                    }
                )
            }
        }

        if let config {
            showToast(config)
        }
    }

    private func removeEventFromCalendar() {
        // Note: EventKit does not give access to the updated EKEvent.
        withAnimation {
            draftPlannerEvent.date =
                draftPlannerEvent.date.roundedDownNearest5Minutes
            draftPlannerEvent.calendarEvent = nil
        }
    }

    private func ensureLocationWhenTimed() {
        if draftPlannerEvent.hasTime, draftPlannerEvent.location == nil {
            draftPlannerEvent.location = defaultLocation
        }
    }
}
