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
        if initialPlannerEvent != nil && initialCalendarEvent != nil {
            fatalError(
                "ERROR: Cannot initialize EventFormView with both a PlannerEvent and a CalendarEvent"
            )
            return
        }

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

            // TODO: Start vs End Date
            draftPlannerEvent.date = calEvent.startDate
            draftPlannerEvent.calendarEvent = calEvent

            if calEvent.calendar.allowsContentModifications {
                _selectedDetent = State(initialValue: .height(2600))
            }
        } else if let plannerEvent {
            draftPlannerEvent.title = plannerEvent.title
            draftPlannerEvent.date = plannerEvent.date
            draftPlannerEvent.untimed = plannerEvent.untimed
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

    // @State private var draftCalendarEvent: EKEvent?
    @State private var draftPlannerEvent: PlannerEvent

    private var isValid: Bool {
        !draftPlannerEvent.title.isEmpty
            && (draftPlannerEvent.date != initialPlannerEvent?.date
                || draftPlannerEvent.title != initialPlannerEvent?.title
                || draftPlannerEvent.calendarEvent
                    != initialPlannerEvent?.calendarEvent)
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
                    displayedComponents: !draftPlannerEvent.untimed
                        ? [.date, .hourAndMinute] : .date
                )

                Toggle("No specific time", isOn: $draftPlannerEvent.untimed)
                    .tint(accentColor.swiftUIColor)
            }
            .animateSynchronousAction(from: draftPlannerEvent.untimed)
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

                if let event, action == .saved {
                    handleCalendarEventChange(event)
                    return
                }

                updateCalendarData()
                dismiss()
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
                        guard let calEvent = draftPlannerEvent.calendarEvent
                        else { return }

                        draftPlannerEvent.title = calEvent.title
                        draftPlannerEvent.date = calEvent.startDate
                        draftPlannerEvent.untimed = false

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

                    event.title = draftPlannerEvent.title

                    // TODO: follow same time standards as apple
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
        
        // ------------------------------------------------------------------
        // 1. Delete stale calendar event if one exists.
        // ------------------------------------------------------------------
        
        if let initialCalendarEvent {

            // Delete the original calendar event and refresh the store.

            calendarStore.delete(event: initialCalendarEvent)

            // TODO: will the events be up-to-date below?
            calendarStore.loadFreshCache(
                hiddenCalendarIds: plannerSettings.hiddenCalendarIds
            )

        }
        
        // ------------------------------------------------------------------
        // 2. TODO: Get the planners the event lands in. Place it in the earliest one
        // ------------------------------------------------------------------

        // TODO: get the planner the event lands in (could be multiple)
        let targetDatestamp = draftPlannerEvent.date

        // TODO: get the planners that the event could land in (3 total)

        // load in those events

        let hasEventMoved =
            initialPlannerEvent?.planner?.datestamp != targetDatestamp

        let planner = modelContext.loadPlanner(for: targetDatestamp)
        let combinedEvents = getPlannerEvents(for: planner)
        let bottomSortIndex = (combinedEvents.last?.sortIndex ?? 0) + 8.0

        // ------------------------------------------------------------------
        // 3. Build the PlannerEvent
        // ------------------------------------------------------------------

        var event: PlannerEvent? = nil

        if let initialPlannerEvent {
            
            // Reuse the existing planner event.
            
            event = initialPlannerEvent

            guard let event else {
                assertionFailure(
                    "ERROR EventForm.savePlannerEvent: Failed to build saved event(1)"
                )
                dismiss()
                return
            }

            event.title = draftPlannerEvent.title
            event.date = draftPlannerEvent.date
            event.untimed = draftPlannerEvent.untimed

            if hasEventMoved {
                // Transfered events get placed at the bottom of their new planner.
                event.sortIndex = bottomSortIndex
            }

        } else {
            
            // Save the draft planner event to the context.

            event = draftPlannerEvent

            guard let event else {
                assertionFailure(
                    "ERROR EventForm.savePlannerEvent: Failed to build saved event(2)"
                )
                dismiss()
                return
            }

            event.sortIndex = bottomSortIndex

            modelContext.insert(event)
        }
        
        guard let event else {
            assertionFailure(
                "ERROR EventForm.savePlannerEvent: Failed to build saved event(3)"
            )
            dismiss()
            return
        }

        // TODO: load in all events from synchronized function below

        let validSortIndex = generateValidPlannerEventSortIndex(
            for: event,
            in: combinedEvents + [event]  // TODO: Ensure the planner contains the event. Is this needed?
        )

        if validSortIndex != event.sortIndex {
            event.sortIndex = validSortIndex
        }
        
            // TODO: add this to model context
        do {
            try modelContext.save()
        } catch {
            assertionFailure("Failed to save planner event: \(error)")
        }

        dismiss()

        // TODO: will the draftPlannerEvent have the same ID when it is saved?
        handleEventChange(.planner(id: event.id, sortIndex: validSortIndex))

    }

    private func handleCalendarEventChange(_ event: EKEvent) {

        updateCalendarData()

        // Delete stale planner events if the new event is a planner chip.
        if event.isAllDay {
            if let initialPlannerEvent {
                modelContext.delete(initialPlannerEvent)
            }

            dismiss()
            return
        }

        guard let sourcePlanner else {
            dismiss()
            return
        }

        let sourceRegion = sourcePlanner.region(settings: plannerSettings)

        guard
            let sourceStartOfDay = sourcePlanner.datestamp.startOfDay(
                in: sourceRegion
            )
        else {
            assertionFailure(
                "ERROR EventForm.handleCalendarEventChange: Could not get sourceStartOfDay from \(sourcePlanner.datestamp)"
            )
            return
        }

        let sourceStartOfNextDay = (sourceStartOfDay + 1.days)

        // TODO: Start vs End Dates
        guard
            event.startDate.date >= sourceStartOfDay.date
                && event.startDate.date < sourceStartOfNextDay.date
        else {
            dismiss()
            return
        }

        guard
            let synchronizedTargetEvents = getSynchronizedEvents(
                for: sourcePlanner
            )
        else {
            assertionFailure(
                "ERROR EventForm.handleCalendarEventChange: Could not get synchronized events for \(sourcePlanner.datestamp)"
            )
            return
        }

        guard
            let plannerEvent = synchronizedTargetEvents.first(
                where: {
                    $0.calendarEvent?.calendarItemExternalIdentifier
                        == event.calendarItemExternalIdentifier
                }
            )
        else {
            assertionFailure(
                "ERROR EventForm.handleCalendarEventChange: Saved calendar event not found in rebuilt planner."
            )
            dismiss()
            return
        }

        dismiss()

        handleEventChange(
            .calendar(
                id: event.calendarItemExternalIdentifier,
                sortIndex: plannerEvent.sortIndex
            )
        )
    }

    // Deletes stale planner event and reloads the calendar.
    private func updateCalendarData() {
        if let initialPlannerEvent, initialPlannerEvent.calendarEvent == nil {
            modelContext.delete(initialPlannerEvent)
        }

        calendarStore.loadFreshCache(
            hiddenCalendarIds: plannerSettings.hiddenCalendarIds
        )
    }

    private func getSynchronizedEvents(
        for planner: Planner
    ) -> [PlannerEvent]? {

        let targetRegion = planner.region(settings: plannerSettings)

        guard let startOfDay = planner.datestamp.startOfDay(in: targetRegion)
        else {
            assertionFailure(
                "ERROR EventForm.getSynchronizedEvents: Failed to get startOfDay for \(planner.datestamp)"
            )
            return nil
        }

        let plannerEvents = modelContext.getEvents(for: startOfDay)

        let plannerCalendarData: PlannerCalendarData =
            calendarStore.loadPlannerData(
                plannerKey: planner.key,
                startOfDay: startOfDay,
                hiddenCalendarIds: plannerSettings.hiddenCalendarIds
            )

        let calendarEvents = plannerCalendarData.timedEvents

        let calendarPlannerEvents =
            modelContext.synchronize(
                calendarEvents: calendarEvents,
                into: plannerEvents,
                planner: planner,
                plannerSettings: plannerSettings
            )

        return (plannerEvents + calendarPlannerEvents)
            .filter { !plannerSettings.isPlannerEventChecked($0) }
            .sorted { $0.sortIndex < $1.sortIndex }
    }

}
