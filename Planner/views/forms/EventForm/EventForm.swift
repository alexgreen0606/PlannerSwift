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
    private let sourcePlannerEvent: PlannerEvent?
    private let sourceCalendarEvent: EKEvent?
    private let settings: PlannerSettings

    private let sourceDay: DateInRegion?

    init(
        sourcePlanner: Planner? = nil,
        plannerEvent: PlannerEvent?,
        calendarEvent: EKEvent?,
        settings: PlannerSettings
    ) {
        self.sourcePlannerEvent = plannerEvent
        self.sourcePlanner = sourcePlanner
        self.sourceCalendarEvent = plannerEvent?.calendarEvent ?? calendarEvent
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
        self.sourceDay = {
            guard let sourcePlanner else {
                return nil
            }
            return sourcePlanner.datestamp.startOfDay(
                in: sourcePlanner.region(settings: settings)
            )
        }()
    }

    // Displays the iOS Contact Form (birthday events only).
    private let contact: CNContact?

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var deviceLocationManager: DeviceLocationManager
    @EnvironmentObject private var notificationManager: NotificationManager
    @EnvironmentObject private var plannerCoverManager: PlannerCoverManager

    @State private var sheetDetent: PresentationDetent = .height(480)
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
                    sourceCalendarEvent: sourceCalendarEvent,
                    sourcePlannerEvent: sourcePlannerEvent,
                    sourcePlanner: sourcePlanner,
                    sourceDay: sourceDay,
                    showNotification: showNotification
                )
            }
        }
        .presentationDragIndicator(.hidden)
        .presentationDetents(
            [.height(480), .large],
            selection: $sheetDetent
        )
        .tint(accentColor.color)

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

        let destinationDay = modelContext.handleCalendarEventChange(
            event,
            sourceDay: sourceDay,
            sourcePlannerEvent: sourcePlannerEvent,
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

        showNotification(sourceDay: sourceDay, destinationDay: destinationDay)
    }

    private func showNotification(
        sourceDay: DateInRegion?,
        destinationDay: DateInRegion?,
    ) {
        var config: NotificationConfig?

        if sourcePlanner == nil {
            if let destinationDay {
                config = NotificationConfig(
                    id: UUID(),
                    title: "Event scheduled",
                    subtitle: "for \(destinationDay.notificationDayLabel)",
                    iconConfig: IconConfig(
                        name: "checkmark",
                        primaryColor: Color.green
                    ),
                    onClick: {
                        plannerCoverManager.context = PlannerCoverContext(
                            datestamp: destinationDay.datestamp
                        )
                    }
                )
            }
        } else if let destinationDay {
            if destinationDay.datestamp != sourceDay?.datestamp {
                config = NotificationConfig(
                    id: UUID(),
                    title: "Event rescheduled",
                    subtitle: "for \(destinationDay.notificationDayLabel)",
                    iconConfig: IconConfig(
                        name: "checkmark",
                        primaryColor: Color.green
                    ),
                    onClick: {
                        plannerCoverManager.context = PlannerCoverContext(
                            datestamp: destinationDay.datestamp
                        )
                    }
                )
            }
        } else if draftPlannerEvent.calendarEvent == nil,
            sourceCalendarEvent != nil
        {
            config = NotificationConfig(
                id: UUID(),
                title: "Event deleted",
                subtitle: "from calendar",
                iconConfig: IconConfig(
                    name: "checkmark",
                    primaryColor: Color.green
                ),
                onClick: nil
            )
        }

        if let config {
            DispatchQueue.main.async {
                notificationManager.addNotification(config)
            }
        }
    }

    private func removeEventFromCalendar() {
        // Note: EventKit does not give access to the updated EKEvent.
        draftPlannerEvent.calendarEvent = nil
        sheetDetent = .height(480)
    }

    private func ensureLocationWhenTimed() {
        if draftPlannerEvent.hasTime, draftPlannerEvent.location == nil {
            draftPlannerEvent.location = defaultLocation
        }
    }

}
