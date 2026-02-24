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

struct DraftPlannerEvent {
    var title: String
    var date: Date
    var hasTime: Bool
    var locationSource: LocationSource
    var location: Location?
    var calendarEvent: EKEvent?

    // Nil means the current device location is used.
    private func location(settings: PlannerSettings, planner: Planner?)
        -> Location?
    {
        switch locationSource {
        case .custom:
            guard let location else {
                fatalError(
                    "ERROR EventForm.location: Draft is set to custom location but no location is set."
                )
            }

            return location
        case .planner:
            guard let planner else {
                fatalError(
                    "ERROR EventForm.location: Draft is set to planner location but no planner was passed."
                )
            }

            return planner.location(settings: settings)
        case .home:
            return settings.homeLocation
        case .current:
            return nil
        }
    }

    func region(settings: PlannerSettings, planner: Planner?) -> Region {
        location(settings: settings, planner: planner)?.region ?? .local
    }

    func locationLabel(
        localCityName: String,
        settings: PlannerSettings,
        planner: Planner?
    ) -> String {
        location(settings: settings, planner: planner)?.name ?? localCityName
    }
}

struct EventFormView: View {
    private let sourcePlanner: Planner?
    private let initialPlannerEvent: PlannerEvent?
    private let initialCalendarEvent: EKEvent?
    private let settings: PlannerSettings
    private let handleEventChange: (PlannerEventPositionChange) -> Void

    init(
        sourcePlanner: Planner? = nil,
        plannerEvent: PlannerEvent?,
        calendarEvent: EKEvent?,
        settings: PlannerSettings,
        handleEventChange: @escaping (PlannerEventPositionChange) -> Void
    ) {
        self.initialPlannerEvent = plannerEvent
        self.sourcePlanner = sourcePlanner
        self.initialCalendarEvent = plannerEvent?.calendarEvent ?? calendarEvent
        self.settings = settings
        self.handleEventChange = handleEventChange

        var draftPlannerEvent = DraftPlannerEvent(
            title: "",
            date: Date(),
            hasTime: false,
            locationSource: .current,
            location: nil,
            calendarEvent: nil
        )

        if sourcePlanner == nil {
            // Use the home location for new events that are not tied to a planner.
            draftPlannerEvent.locationSource = .home
        }

        var contact: CNContact? = nil

        if let calEvent = plannerEvent?.calendarEvent ?? calendarEvent {
            
            draftPlannerEvent.title = calEvent.title
            draftPlannerEvent.date = calEvent.startDate
            draftPlannerEvent.hasTime = true

            if let structuredLocation = calEvent.structuredLocation,
                let latitude = structuredLocation.geoLocation?.coordinate
                    .latitude,
                let longitude = structuredLocation.geoLocation?.coordinate
                    .longitude, let locationLabel = calEvent.location
            {
                
                // Add the calendar event's location to the event.

                draftPlannerEvent.location = Location(
                    name: locationLabel,
                    latitude: latitude,
                    longitude: longitude,
                    timeZoneIdentifier: calEvent.timeZone?.identifier
                        ?? Region.local.timeZone.identifier
                )

                draftPlannerEvent.locationSource = .custom

            }

            if calEvent.calendar.allowsContentModifications {
                _selectedDetent = State(initialValue: .height(2600))
            }
            
            draftPlannerEvent.calendarEvent = calEvent

        } else if let plannerEvent {

            draftPlannerEvent.title = plannerEvent.title
            draftPlannerEvent.hasTime = plannerEvent.hasTime
            draftPlannerEvent.location = plannerEvent.location
            draftPlannerEvent.locationSource = plannerEvent.locationSource

            if !plannerEvent.hasTime {

                // Initialize the event time so it is user-friendly.

                let now = DateInRegion(Date(), region: .local)

                var startDayInRegion: DateInRegion
                if let sourcePlanner {

                    // Build the initial event time based on this hour on the day of the planner.

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

                    // Build the initial event time based on right now (Create Event form only)

                    startDayInRegion = now
                }

                // Round the time down to the start of the hour.
                draftPlannerEvent.date =
                    startDayInRegion
                    .dateAtStartOf(.hour)
                    .date

            } else {
                draftPlannerEvent.date = plannerEvent.date
            }

        }

        // Open the contact for birthday events.
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

    // Overrides all other behavior in this sheet and displays the Contact form.
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

    @State private var selectedDetent: PresentationDetent = .height(460)
    @State private var draftPlannerEvent: DraftPlannerEvent

    private var isValid: Bool {
        !draftPlannerEvent.title.isEmpty
            && (draftPlannerEvent.date != initialPlannerEvent?.date
                || draftPlannerEvent.title != initialPlannerEvent?.title
                || draftPlannerEvent.calendarEvent
                    != initialPlannerEvent?.calendarEvent
                || draftPlannerEvent.hasTime != initialPlannerEvent?.hasTime
                || draftPlannerEvent.location != initialPlannerEvent?.location
                || draftPlannerEvent.locationSource
                    != initialPlannerEvent?.locationSource)
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
                                settings: settings,
                                planner: sourcePlanner
                            )
                            .timeZone
                    )

                    Toggle("Time", isOn: $draftPlannerEvent.hasTime)
                        .tint(accentColor.swiftUIColor)
                }

                Section {
                    NavigationLink {
                        LocationSearchView(
                            initialLocation: draftPlannerEvent.location,
                            initialLocationSource: draftPlannerEvent
                                .locationSource,
                            title: "Edit Event Location",
                            sourcePlanner: sourcePlanner,
                            mode: .event
                        ) { source, location in

                            draftPlannerEvent.location = location
                            draftPlannerEvent.locationSource = source

                        }
                    } label: {
                        HStack {

                            Text("Location")

                            Spacer()

                            Text(
                                draftPlannerEvent.locationLabel(
                                    localCityName: deviceLocationManager
                                        .cityName,
                                    settings: settings,
                                    planner: sourcePlanner
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
                            settings: settings,
                            planner: sourcePlanner
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
                        systemImage: "calendar.badge.minus"
                    ) {
                        // Note: EventKit does not give access to the updated EKEvent.
                        draftPlannerEvent.calendarEvent = nil
                        selectedDetent = .height(460)
                    }
                }
            }
        } else {
            ViewCalendarEventFormView(event: event)
                .ignoresSafeArea()
        }
    }

    @ToolbarContentBuilder
    private var plannerEventTopRightToolbar: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button("Save", systemImage: "checkmark") {
                savePlannerEvent()
            }
            .disabled(!isValid)
            .tint(accentColor.swiftUIColor)
        }
    }

    @ToolbarContentBuilder
    private var plannerEventBottomToolbar: some ToolbarContent {
        if !calendarStore.accessDenied {
            ToolbarItem(placement: .bottomBar) {
                AccentButtonView(
                    label: "Add To Calendar",
                    systemImage: "calendar.badge.plus"
                ) {

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
            }
            .sharedBackgroundVisibility(.hidden)
        }
    }

    private func savePlannerEvent() {

        modelContext.savePlannerEventChanges(
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

    private func handleCalendarEventChange(_ event: EKEvent?) {

        modelContext.savePlannerEventChanges(
            event,
            initialPlannerEvent: initialPlannerEvent,
            settings: settings
        )

        reloadGlobalCalendarData()

        dismiss()
    }

    // Deletes stale planner event and reloads the calendar.
    private func reloadGlobalCalendarData() {
        calendarStore.loadFreshCache(
            hiddenCalendarIds: settings.hiddenCalendarIds
        )
    }

}
