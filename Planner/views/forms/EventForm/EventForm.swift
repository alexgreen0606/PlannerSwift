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

struct EventFormView: View {
    private let sourcePlanner: Planner?
    private let initialPlannerEvent: PlannerEvent?
    private let initialCalendarEvent: EKEvent?
    private let settings: PlannerSettings
    private let handleEventChange: () -> Void

    init(
        sourcePlanner: Planner? = nil,
        plannerEvent: PlannerEvent?,
        calendarEvent: EKEvent?,
        settings: PlannerSettings,
        handleEventChange: @escaping () -> Void
    ) {
        self.initialPlannerEvent = plannerEvent
        self.sourcePlanner = sourcePlanner
        self.initialCalendarEvent = plannerEvent?.calendarEvent ?? calendarEvent
        self.settings = settings
        self.handleEventChange = handleEventChange

        // ------------------------------------------------------------------
        // Build the draft event
        // ------------------------------------------------------------------

        var draftPlannerEvent = DraftPlannerEvent()

        if sourcePlanner == nil {
            // Use the home location for new events that are not tied to a planner (Planner homepage).
            draftPlannerEvent.location = settings.homeLocation
        }

        if let calEvent = plannerEvent?.calendarEvent ?? calendarEvent {

            // ----------------------------------------------------------
            // Initialize the calendar event form.
            // Carry calendar event data over to the draft planner event.
            // ----------------------------------------------------------

            draftPlannerEvent.title = calEvent.title
            draftPlannerEvent.date = calEvent.startDate
            draftPlannerEvent.hasTime = true

            // Build a location object for the draft if the calendar event has a location.
            if let structuredLocation = calEvent.structuredLocation,
                let latitude = structuredLocation.geoLocation?.coordinate
                    .latitude,
                let longitude = structuredLocation.geoLocation?.coordinate
                    .longitude, let locationLabel = calEvent.location
            {

                draftPlannerEvent.location = Location(
                    name: locationLabel,
                    latitude: latitude,
                    longitude: longitude,
                    timeZoneIdentifier: calEvent.timeZone?.identifier
                        ?? Region.local.timeZone.identifier
                )

            }

            // Max out the sheet height if this event can be edited.
            if calEvent.calendar.allowsContentModifications {
                _selectedDetent = State(initialValue: .height(2600))
            }

            draftPlannerEvent.calendarEvent = calEvent

        } else if let plannerEvent {

            // ----------------------------------------------------------
            // Initialize the planner event form.
            // ----------------------------------------------------------

            draftPlannerEvent.title = plannerEvent.title
            draftPlannerEvent.hasTime = plannerEvent.hasTime
            draftPlannerEvent.location = plannerEvent.location

            if !plannerEvent.hasTime {

                // Initialize the event time so it is user-friendly.

                var startDayInRegion: DateInRegion
                let now = DateInRegion(Date(), region: .local)

                if let sourcePlanner {

                    // Use the current hour on the day of the selected planner.

                    let currentHour = now.hour

                    startDayInRegion =
                        sourcePlanner.datestamp.startOfDay(
                            in: sourcePlanner.region(settings: settings)
                        ) ?? now

                    startDayInRegion =
                        startDayInRegion.dateBySet(
                            hour: currentHour,
                            min: 0,
                            secs: 0
                        ) ?? now
                } else {

                    // Use the current hour (Create Event form only).

                    startDayInRegion = now
                }

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
        // Load in the contact for birthday events
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

                _selectedDetent = State(initialValue: .height(2600))
            } catch {
                assertionFailure("Failed to fetch birthday contact: \(error)")
            }
        }

        self.contact = contact
        self.draftPlannerEvent = draftPlannerEvent

    }

    // Overrides all other behavior in this sheet and displays the Contact form (Birthday events only).
    private let contact: CNContact?

    @AppStorage("keepPastPlansDuration") private var keepPastPlansDuration:
        KeepPastPlansDuration =
            KeepPastPlansDuration.oneMonth

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var todaystampWatcher: TodaystampWatcher
    @EnvironmentObject private var deviceLocationManager: DeviceLocationManager

    // Stores all form data.
    @State private var draftPlannerEvent: DraftPlannerEvent

    @State private var selectedDetent: PresentationDetent = .height(460)

    private var canSave: Bool {
        !draftPlannerEvent.title.isEmpty
            && isDraftDirty(
                draft: draftPlannerEvent,
                initial: initialPlannerEvent
            )
    }

    private var isCreateForm: Bool {
        initialPlannerEvent == nil && initialCalendarEvent == nil
    }

    var body: some View {
        Group {
            if let contact {
                ContactFormView(contact: contact)
                    .ignoresSafeArea()
            } else if let draftCalendarEvent = draftPlannerEvent.calendarEvent {
                calendarEventForm(for: draftCalendarEvent)
            } else {
                plannerEventForm
            }
        }
        .presentationDragIndicator(.hidden)
        .presentationDetents(
            [.height(460), .height(2600)],
            selection: $selectedDetent
        )
    }

    // MARK: - Planner Event Form

    private var plannerEventForm: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $draftPlannerEvent.title)
                        .textInputAutocapitalization(.words)
                }
                .listSectionMargins(.top, 0)

                Section {
                    DatePicker(
                        "Date",
                        selection: $draftPlannerEvent.date,
                        in: keepPastPlansDuration
                            .cutoffDate...todaystampWatcher
                            .maxCalendarDate,
                        displayedComponents: draftPlannerEvent.hasTime
                            ? [.date, .hourAndMinute] : .date
                    )
                    .environment(
                        \.timeZone,
                        draftPlannerEvent
                            .region(
                                planner: sourcePlanner,
                                settings: settings,
                                deviceLocation: deviceLocationManager.location
                            )
                            .timeZone
                    )

                    Toggle("Time", isOn: $draftPlannerEvent.hasTime)
                        .tint(accentColor.swiftUIColor)
                }

                Section {
                    NavigationLink {
                        LocationSearchView(
                            title: "Edit Event Location",
                            mode: .event,
                            settings: settings,
                            initialLocation: draftPlannerEvent.location,
                            sourcePlanner: sourcePlanner,
                            saveSelection: handleLocationChange
                        )
                    } label: {
                        HStack {

                            Text("Location")

                            Spacer()

                            Text(
                                draftPlannerEvent.locationLabel(
                                    planner: sourcePlanner,
                                    settings: settings,
                                    deviceLocation: deviceLocationManager.location
                                )
                            )
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        }
                    }
                } footer: {
                    let timeZoneAbbreviation =
                        draftPlannerEvent
                        .region(
                            planner: sourcePlanner,
                            settings: settings,
                            deviceLocation: deviceLocationManager.location
                        )
                        .timeZone
                        .abbreviation() ?? "Unknown Time Zone"

                    Text("Time Zone: \(timeZoneAbbreviation)")
                }

            }
            .navigationTitle(isCreateForm ? "Create Plan" : "Edit Plan")
            .navigationBarTitleDisplayMode(.inline)
            .scrollDisabled(true)
            .toolbar {
                plannerEventTopRightToolbar
                plannerEventBottomToolbar
            }
        }
    }

    @ToolbarContentBuilder
    private var plannerEventTopRightToolbar: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button("Save", systemImage: "checkmark", action: savePlannerEvent)
                .disabled(!canSave)
                .tint(accentColor.swiftUIColor)
        }
    }

    @ToolbarContentBuilder
    private var plannerEventBottomToolbar: some ToolbarContent {
        if !calendarStore.accessDenied {
            ToolbarItem(placement: .bottomBar) {
                AccentButtonView(
                    label: "Add To Calendar",
                    systemImage: "calendar.badge.plus",
                    onTap: addEventToCalendar
                )
            }
            .sharedBackgroundVisibility(.hidden)
        }
    }

    private func savePlannerEvent() {

        modelContext.saveEventFormChanges(
            draftPlannerEvent,
            initialPlannerEvent: initialPlannerEvent,
            initialCalendarEvent: initialCalendarEvent
        )

        if let initialCalendarEvent {

            // Delete the original calendar event and refresh the store.

            calendarStore.delete(event: initialCalendarEvent)

            calendarStore.loadFreshCache(
                hiddenCalendarIds: settings.hiddenCalendarIds
            )

        }

        dismiss()

    }

    private func handleLocationChange(
        _ location: Location?
    ) {
        draftPlannerEvent.location = location
    }

    // MARK: - Calendar Event Form

    @ViewBuilder
    private func calendarEventForm(for event: EKEvent) -> some View {
        if event.calendar.allowsContentModifications {
            EditCalendarEventFormView(
                event: event,
                eventStore: calendarStore.ekEventStore
            ) { action, event in
                guard action != .canceled else {
                    dismiss()
                    return
                }

                handleCalendarEventChange(event)
            }
            .tint(accentColor.swiftUIColor)
            .ignoresSafeArea()
            .overlay {
                VStack {

                    Spacer()

                    AccentButtonView(
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

    private func handleCalendarEventChange(_ event: EKEvent?) {

        modelContext.saveEventFormChanges(
            event,
            initialPlannerEvent: initialPlannerEvent,
            settings: settings
        )

        reloadGlobalCalendarData()

        dismiss()
    }

    // MARK: - Helper Functions

    // Deletes stale planner event and reloads the calendar.
    private func reloadGlobalCalendarData() {
        calendarStore.loadFreshCache(
            hiddenCalendarIds: settings.hiddenCalendarIds
        )
    }

    private func addEventToCalendar() {

        // Build a calendar event to represent the form values.
        let event =
            initialCalendarEvent
            ?? EKEvent(
                eventStore: calendarStore.ekEventStore
            )
        event.calendar =
            initialCalendarEvent?.calendar
            ?? calendarStore.ekEventStore
            .defaultCalendarForNewEvents

        if let location = draftPlannerEvent.location {

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
        selectedDetent = .height(2600)
    }

    private func removeEventFromCalendar() {
        // Note: EventKit does not give access to the updated EKEvent.
        draftPlannerEvent.calendarEvent = nil
        selectedDetent = .height(460)
    }

    private func isDraftDirty(draft: DraftPlannerEvent, initial: PlannerEvent?)
        -> Bool
    {
        draft.date != initial?.date
            || draft.title != initial?.title
            || draft.calendarEvent != initial?.calendarEvent
            || draft.hasTime != initial?.hasTime
            || draft.location != initial?.location
    }

}
