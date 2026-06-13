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
        plannerEvent: PlannerEvent? = nil,
        ekEventStore: EKEventStore? = nil,
        settings: PlannerSettings
    ) {
        sourcePlannerEvent = plannerEvent
        self.sourcePlanner = sourcePlanner
        self.settings = settings
        
        let calendarEvent: EKEvent? = {
            guard let plannerEvent, let ekEventStore else {
                return nil
            }
            
            return ekEventStore.getEkEvent(for: plannerEvent)
        }()
        
        sourceCalendarEvent = calendarEvent

        // ------------------------------------------------------------------
        // Build the draft event from the initial data.
        // ------------------------------------------------------------------

        var draftPlannerEvent = DraftPlannerEvent()

        if let calEvent = sourceCalendarEvent {
            // ----------------------------------------------------------
            // Initialize the calendar event form.
            // Carry calendar event data over to the draft planner event.
            // ----------------------------------------------------------

            draftPlannerEvent.title = calEvent.title
            draftPlannerEvent.date = calEvent.startDate
            draftPlannerEvent.hasTime = true
            draftPlannerEvent.location = calEvent.location(
                existingPlannerEvent: sourcePlannerEvent
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
                        sourcePlanner.startOfDay(settings: settings)

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
    @EnvironmentObject private var calendarStore: CalendarService
    @EnvironmentObject private var PlannerSyncStore: PlannerSyncService
    @EnvironmentObject private var LocationService: LocationService
    @EnvironmentObject private var PlannerCoverStore: PlannerCoverStore
    @EnvironmentObject private var todayService: TodayService

    @State private var draftPlannerEvent: DraftPlannerEvent

    @State private var showDeleteConfirmation = false

    private var isCreateForm: Bool {
        sourcePlannerEvent == nil && sourceCalendarEvent == nil
    }

    private var defaultLocation: Location? {
        sourcePlanner?.location(
            settings: settings,
            deviceLocation: LocationService.deviceLocation
        )
            ?? settings.homeLocation(
                deviceLocation: LocationService.deviceLocation
            )
    }

    private var showCalendarEventSheet: Binding<Bool> {
        Binding(
            get: {
                draftPlannerEvent.calendarEvent != nil
            },
            set: { newValue in
                if !newValue {
                    draftPlannerEvent.calendarEvent = nil
                }
            }
        )
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ZStack {
                if draftPlannerEvent.calendarEvent == nil {
                    PlannerEventFormView(
                        draftPlannerEvent: $draftPlannerEvent,
                        settings: settings,
                        defaultLocation: defaultLocation,
                        sourceCalendarEvent: sourceCalendarEvent,
                        sourcePlannerEvent: sourcePlannerEvent,
                        sourcePlanner: sourcePlanner,
                        showNotification: showNotification
                    )
                    .toolbar {
                        if !isCreateForm {
                            ToolbarItem(placement: .bottomBar) {
                                let button = Button("", systemImage: "trash") {
                                    showDeleteConfirmation = true
                                }
                                .tint(Color.red)

                                if let sourceCalendarEvent {
                                    button
                                    // TODO: add confirmation for calendar event
                                } else if let sourcePlannerEvent {
                                    button
                                        .withConfirmation(
                                            deletePlannerEventConfig(
                                                event: sourcePlannerEvent,
                                                inForm: true,
                                                delete: deleteSourceEvent
                                            ),
                                            isPresented: $showDeleteConfirmation
                                        )
                                }
                            }
                        }

                        ToolbarSpacer(placement: .bottomBar)

                        ToolbarItem(placement: .bottomBar) {
                            Button(
                                "Add to Calendar",
                                action: addEventToCalendar
                            )
                            .fontWeight(.medium)
                        }
                    }
                }
            }

            // TODO: move to planner form Ensure event location exists when hasTime is set to true.
            .onChange(of: draftPlannerEvent.hasTime) { _, _ in
                ensureLocationWhenTimed()
            }

        }
        .sheet(isPresented: showCalendarEventSheet) {
            calendarEventForm(for: draftPlannerEvent.calendarEvent!)
                .toolbar {
                    ToolbarSpacer(placement: .bottomBar)

                    ToolbarItem(placement: .bottomBar) {
                        Button(
                            "Remove from Calendar",
                            action: removeEventFromCalendar
                        )
                        .fontWeight(.medium)
                    }
                }
        }

        // TODO: change detents. Maybe separate form for view calendar events.
        .presentationBackground(Color.sheetBackground)
        .presentationDetents(
            draftPlannerEvent.calendarEvent != nil
                && draftPlannerEvent.calendarEvent?.calendar
                    .allowsContentModifications == false
                ? [.height(300)] : [.large]
        )
        .interactiveDismissDisabled(true)
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
            .navigationBarBackButtonHidden(true)
        } else {
            ViewCalendarEventFormView(event: event)
                .ignoresSafeArea()
        }
    }

    // MARK: - Functions

    private func saveCalendarEvent(_ event: EKEvent?) {
        let destinationDatestamps = modelContext.handleCalendarEventChange(
            event,
            sourcePlanner: sourcePlanner,
            sourcePlannerEvent: sourcePlannerEvent,
            settings: settings
        )

        // TODO: only do this if the event was recurring or is recurring.
        // Refresh calendar in case of recurring events.
        DispatchQueue.main.async(
            execute: PlannerSyncStore.syncCalendar
        )

        dismiss()

        showNotification(
            sourceDatestamp: sourcePlanner?.datestamp,
            destinationDatestamps: destinationDatestamps,
            finalEkEvent: event
        )
    }

    private func showNotification(
        sourceDatestamp: String?,
        destinationDatestamps: Set<String>,
        finalEkEvent _: EKEvent? = nil
    ) {
        guard !destinationDatestamps.isEmpty else { return }

        var config: Toast?

        if sourcePlanner == nil {
            let earliestDatestamp = destinationDatestamps.sorted().first!
            config = Toast(
                title:
                    "Successfully created event!",
                subtitle:
                    "\(earliestDatestamp.dateWithYear) | \(earliestDatestamp.weekday)",
                iconConfig: IconConfig(
                    name: "calendar.day.timeline.leading",
                    primaryColor: Color.label,
                    secondaryColor: Color.secondary
                ),
                variant: .tab,
                action: {
                    PlannerCoverStore.context = PlannerCoverContext(
                        datestamp: earliestDatestamp
                    )
                }
            )
        } else if let sourceDatestamp {
            if !destinationDatestamps.contains(sourceDatestamp) {
                let earliestDatestamp = destinationDatestamps.sorted().first!

                let primaryColor =
                    earliestDatestamp > sourceDatestamp
                    ? Color.secondary : Color.label
                let secondaryColor =
                    earliestDatestamp > sourceDatestamp
                    ? Color.label : Color.secondary

                config = Toast(
                    title: "Successfully moved event!",
                    subtitle:
                        "\(earliestDatestamp.dateWithYear) | \(earliestDatestamp.weekday)",
                    iconConfig: IconConfig(
                        name: "arrow.left.arrow.right",
                        primaryColor: primaryColor,
                        secondaryColor: secondaryColor
                    ),
                    action: {
                        PlannerCoverStore.context = PlannerCoverContext(
                            datestamp: earliestDatestamp
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
        draftPlannerEvent.date =
            draftPlannerEvent.date.roundedDownNearest5Minutes
        draftPlannerEvent.calendarEvent = nil
    }

    private func addEventToCalendar() {
        // Build a calendar event to represent the form values.
        let event =
            sourceCalendarEvent
            ?? EKEvent(
                eventStore: calendarStore.ekEventStore
            )
        event.calendar =
            sourceCalendarEvent?.calendar
            ?? calendarStore.ekEventStore
            .defaultCalendarForNewEvents

        if let location = draftPlannerEvent.location ?? defaultLocation {
            // Location display name.
            event.location = location.name

            // Location coordinates.
            let structuredLocation = EKStructuredLocation(
                title: location.name
            )
            structuredLocation.geoLocation = CLLocation(
                latitude: location.latitude,
                longitude: location.longitude
            )
            event.structuredLocation = structuredLocation

            // Location time zone.
            event.timeZone = TimeZone(
                identifier: location.timeZoneIdentifier
            )
        }

        event.title = draftPlannerEvent.title
        event.startDate = draftPlannerEvent.date
        event.endDate = Calendar.current.date(
            byAdding: .hour,
            value: 1,
            to: draftPlannerEvent.date
        )

        draftPlannerEvent.calendarEvent = event
    }

    private func deleteSourceEvent() {
        dismiss()

        if let sourceCalendarEvent {
            guard
                calendarStore.ekEventStore.attemptDeleteEvent(
                    sourceCalendarEvent
                )
            else {
                return
            }
        }

        if let sourcePlannerEvent {
            // TODO: should i do the official deletion here?
            modelContext.safeDelete(sourcePlannerEvent)
        }
    }

    private func ensureLocationWhenTimed() {
        if draftPlannerEvent.hasTime, draftPlannerEvent.location == nil {
            draftPlannerEvent.location = defaultLocation
        }
    }
}
