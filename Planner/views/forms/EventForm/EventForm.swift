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
    private let plannerSettings: PlannerSettings
    private let handleEventChange: (PlannerEventPositionChange) -> Void

    init(
        sourcePlanner: Planner? = nil,
        plannerEvent: PlannerEvent?,
        calendarEvent: EKEvent?,
        plannerSettings: PlannerSettings,
        handleEventChange: @escaping (PlannerEventPositionChange) -> Void
    ) {
        self.initialPlannerEvent = plannerEvent
        self.sourcePlanner = sourcePlanner
        self.initialCalendarEvent = plannerEvent?.calendarEvent ?? calendarEvent
        self.plannerSettings = plannerSettings
        self.handleEventChange = handleEventChange

        let draftPlannerEvent = PlannerEvent(
            date: Date(),
            calendarEvent: nil,
            sortIndex: 0
        )

        var contact: CNContact? = nil

        if let calEvent = plannerEvent?.calendarEvent ?? calendarEvent {

            draftPlannerEvent.date = calEvent.startDate
            draftPlannerEvent.calendarEvent = calEvent

            if calEvent.calendar.allowsContentModifications {
                _selectedDetent = State(initialValue: .height(2600))
            }

        } else if let plannerEvent {

            draftPlannerEvent.title = plannerEvent.title
            draftPlannerEvent.hasTime = plannerEvent.hasTime

            if !plannerEvent.hasTime {

                // Initialize the event time so it is user-friendly.

                let now = DateInRegion(Date(), region: .local)

                var startDayInRegion: DateInRegion
                if let sourcePlanner {

                    // Build the initial event time based on this hour on the day of the planner.

                    let currentHour = now.hour

                    startDayInRegion =
                        sourcePlanner.datestamp.startOfDay(
                            in: sourcePlanner.region(settings: plannerSettings)
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

    @State private var selectedDetent: PresentationDetent = .height(340)
    @State private var draftPlannerEvent: PlannerEvent

    private var isValid: Bool {
        !draftPlannerEvent.title.isEmpty
            && (draftPlannerEvent.date != initialPlannerEvent?.date
                || draftPlannerEvent.title != initialPlannerEvent?.title
                || draftPlannerEvent.calendarEvent
                    != initialPlannerEvent?.calendarEvent
                || draftPlannerEvent.hasTime != initialPlannerEvent?.hasTime)
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
            [.height(340), .height(2600)],
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
                    sourcePlanner?.region(settings: plannerSettings).timeZone
                        ?? .current
                )

                Toggle("Time", isOn: $draftPlannerEvent.hasTime)
                    .tint(accentColor.swiftUIColor)
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
                        guard let calEvent = draftPlannerEvent.calendarEvent
                        else { return }

                        draftPlannerEvent.title = calEvent.title
                        draftPlannerEvent.date = calEvent.startDate
                        draftPlannerEvent.hasTime = true

                        draftPlannerEvent.calendarEvent = nil
                        selectedDetent = .height(340)
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

                    if let location = sourcePlanner?.location {
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
                hiddenCalendarIds: plannerSettings.hiddenCalendarIds
            )

        }

        dismiss()

    }

    private func handleCalendarEventChange(_ event: EKEvent?) {

        modelContext.savePlannerEventChanges(
            event,
            initialPlannerEvent: initialPlannerEvent,
            plannerSettings: plannerSettings
        )

        reloadGlobalCalendarData()

        dismiss()
    }

    // Deletes stale planner event and reloads the calendar.
    private func reloadGlobalCalendarData() {
        calendarStore.loadFreshCache(
            hiddenCalendarIds: plannerSettings.hiddenCalendarIds
        )
    }

}
