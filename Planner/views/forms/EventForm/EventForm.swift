//
//  EventForm.swift
//  Planner
//
//  Created by Alex Green on 1/29/26.
//

import Contacts
import ContactsUI
import EventKit
import EventKitUI
import SwiftData
import SwiftDate
import SwiftUI

// Clean

struct EventFormView: View {
    private let sourcePlanner: Planner?
    private let initialPlannerEvent: PlannerEvent?
    private let initialCalendarEvent: EKEvent?
    private let settings: PlannerSettings

    init(
        sourcePlanner: Planner? = nil,
        plannerEvent: PlannerEvent?,
        calendarEvent: EKEvent?,
        settings: PlannerSettings
    ) {
        self.initialPlannerEvent = plannerEvent
        self.sourcePlanner = sourcePlanner
        self.initialCalendarEvent = plannerEvent?.calendarEvent ?? calendarEvent
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
                storageEvent: initialPlannerEvent
            )
            draftPlannerEvent.calendarEvent = calEvent

            if calEvent.calendar.allowsContentModifications {
                // Use max height for calendar edit forms.
                _sheetDetent = State(initialValue: .large)
            }

        } else if let plannerEvent {

            // ----------------------------------------------------------
            // Initialize the planner event form.
            // ----------------------------------------------------------

            draftPlannerEvent.title = plannerEvent.title
            draftPlannerEvent.hasTime = plannerEvent.hasTime
            draftPlannerEvent.location = plannerEvent.location

            if !plannerEvent.hasTime {

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

            } else {
                // Use the existing time for the event.
                draftPlannerEvent.date = plannerEvent.date
            }

        }

        // ------------------------------------------------------------------
        // Load in the contact for birthday events.
        // ------------------------------------------------------------------

        var contact: CNContact? = nil

        if calendarEvent?.calendar.type == .birthday,
            let contactId = calendarEvent?.birthdayContactIdentifier
        {

            let store = CNContactStore()

            do {
                contact = try store.unifiedContact(
                    withIdentifier: contactId,
                    keysToFetch: [
                        CNContactViewController.descriptorForRequiredKeys()
                    ] as [CNKeyDescriptor]
                )

                _sheetDetent = State(initialValue: .large)
            } catch {
                assertionFailure("ERROR EventForm.init: \(error)")
            }
        }

        self.contact = contact
        self.draftPlannerEvent = draftPlannerEvent
    }

    // Displays the iOS Contact Form (birthday events only).
    private let contact: CNContact?

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var deviceLocationManager: DeviceLocationManager

    @State private var sheetDetent: PresentationDetent = .height(460)
    @State private var draftPlannerEvent: DraftPlannerEvent

    private var defaultLocation: Location? {
        sourcePlanner?.location(
            settings: settings,
            deviceLocation: deviceLocationManager.deviceLocation
        )
            ?? settings.homeLocation(
                deviceLocation: deviceLocationManager.deviceLocation
            )
    }

    var body: some View {
        ZStack {
            if let contact {
                ContactFormView(contact: contact)
                    .ignoresSafeArea()
            } else if let draftCalendarEvent = draftPlannerEvent.calendarEvent {
                calendarEventForm(for: draftCalendarEvent)
            } else {
                PlannerEventFormView(
                    draftPlannerEvent: $draftPlannerEvent,
                    sheetDetent: $sheetDetent,
                    settings: settings,
                    defaultLocation: defaultLocation,
                    initialCalendarEvent: initialCalendarEvent,
                    initialPlannerEvent: initialPlannerEvent,
                    sourcePlanner: sourcePlanner
                )
            }
        }
        .presentationDragIndicator(.hidden)
        .presentationDetents(
            [.height(460), .large],
            selection: $sheetDetent
        )
        .tint(accentColor.color)

        // Ensure timed event location existence when the device location loads in.
        .externalData(
            key: deviceLocationManager.deviceLocation,
            ready: deviceLocationManager.deviceLocation != nil,
            load: ensureLocationWhenTimed
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
        } else {
            ViewCalendarEventFormView(event: event)
                .ignoresSafeArea()
        }
    }

    // MARK: - Functions

    private func saveCalendarEvent(_ event: EKEvent?) {

        modelContext.handleCalendarEventChange(
            event,
            previousDatestamp: sourcePlanner?.datestamp,
            initialPlannerEvent: initialPlannerEvent,
            settings: settings,
            ekEventStore: calendarStore.ekEventStore
        )

        // Refresh calendar in case of recurring events.
        DispatchQueue.main.async {
            calendarStore.attemptFreshLoad(
                hiddenCalendarIds: settings.hiddenCalendarIds
            )
        }

        dismiss()
    }

    private func removeEventFromCalendar() {
        // Note: EventKit does not give access to the updated EKEvent.
        draftPlannerEvent.calendarEvent = nil
        sheetDetent = .height(460)
    }

    private func ensureLocationWhenTimed() {
        if draftPlannerEvent.hasTime, draftPlannerEvent.location == nil {
            draftPlannerEvent.location = defaultLocation
        }
    }

}
