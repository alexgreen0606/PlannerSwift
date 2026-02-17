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
    private let calendarSettings: CalendarSettings
    private let handleEventChange: (PlannerEventPositionChange) -> Void

    init(
        sourcePlanner: Planner? = nil,
        plannerEvent: PlannerEvent?,
        calendarEvent: EKEvent?,
        plannerSettings: PlannerSettings,
        calendarSettings: CalendarSettings,
        handleEventChange: @escaping (PlannerEventPositionChange) -> Void
    ) {
        self.initialPlannerEvent = plannerEvent
        self.sourcePlanner = sourcePlanner
        self.initialCalendarEvent = plannerEvent?.calendarEvent ?? calendarEvent
        self.plannerSettings = plannerSettings
        self.calendarSettings = calendarSettings
        self.handleEventChange = handleEventChange

        var title = ""
        var hasTime = false
        var date = Date()
        var contact: CNContact? = nil

        if let calEvent = plannerEvent?.calendarEvent ?? calendarEvent {
            _draftCalendarEvent = State(initialValue: calEvent)

            if calEvent.calendar.allowsContentModifications {
                _selectedDetent = State(initialValue: .height(2600))
            }
        } else if let plannerEvent {
            title = plannerEvent.title
            date = plannerEvent.date
            hasTime = !plannerEvent.untimed
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

        let draftPlannerEvent = PlannerEvent(
            date: date,
            calendarEvent: nil,
            sortIndex: 0
        )
        draftPlannerEvent.title = title
        draftPlannerEvent.untimed = !hasTime
        //        _title = State(initialValue: title)
        //        _date = State(initialValue: date)
        //        _hasTime = State(initialValue: hasTime)
        self.draftPlannerEvent = draftPlannerEvent
        self.contact = contact
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

    @State private var draftCalendarEvent: EKEvent?
    @State private var draftPlannerEvent: PlannerEvent
    //    @State private var title: String
    //    @State private var date: Date
    //    @State private var hasTime: Bool

    private var isValid: Bool {
        !draftPlannerEvent.title.isEmpty
            && (draftPlannerEvent.date != initialPlannerEvent?.date
                || draftPlannerEvent.title != initialPlannerEvent?.title
                || draftCalendarEvent
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
            } else if let draftCalendarEvent {
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
            .animateChange(from: draftPlannerEvent.untimed)
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
            NavigationStack {
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
                .toolbar {
                    calendarEventBottomToolbar
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

                    // Create a new calendar event to represent the form values.
                    let event = EKEvent(
                        eventStore: calendarStore.ekEventStore
                    )
                    event.calendar =
                        calendarStore.ekEventStore
                        .defaultCalendarForNewEvents
                    event.title = draftPlannerEvent.title
                    event.startDate = draftPlannerEvent.date
                    event.endDate = Calendar.current.date(
                        byAdding: .hour,
                        value: 1,
                        to: draftPlannerEvent.date
                    )

                    draftCalendarEvent = event
                    selectedDetent = .height(2600)
                }
            }
            .sharedBackgroundVisibility(.hidden)
        }
    }

    @ToolbarContentBuilder
    private var calendarEventBottomToolbar: some ToolbarContent {
        ToolbarItem(placement: .bottomBar) {
            AccentButtonView(
                label: "Remove From Calendar",
                systemImage: "calendar.badge.minus"
            ) {
                guard let calEvent = draftCalendarEvent else { return }

                draftPlannerEvent.title = calEvent.title
                draftPlannerEvent.date = calEvent.startDate
                draftPlannerEvent.untimed = false

                draftCalendarEvent = nil
                selectedDetent = .height(340)
            }
        }
        .sharedBackgroundVisibility(.hidden)
    }

    private func savePlannerEvent() {
        // TODO: implement and add this to model context
        //        let targetDatestamp = date.datestamp
        //        let hasEventMoved =
        //            initialPlannerEvent?.planner?.datestamp != targetDatestamp
        //
        //        let planner = modelContext.loadPlanner(for: targetDatestamp)
        //        let combinedEvents = getPlannerEvents(for: planner)
        //        let bottomSortIndex = (combinedEvents.last?.sortIndex ?? 0) + 8.0
        //
        //        var event =
        //            initialPlannerEvent ?? PlannerEvent(sortIndex: bottomSortIndex)
        //        if hasEventMoved && initialPlannerEvent != nil {
        //            // Transfered events get placed at the bottom of their new planner.
        //            event.sortIndex = bottomSortIndex
        //        }
        //
        //        // Delete the stale calendar event if one exists.
        //        if let calEvent = initialCalendarEvent {
        //
        //            calendarStore.delete(event: calEvent)
        //            calendarStore.refresh(
        //                hiddenCalendarIds: calendarSettings?.hiddenCalendarIds
        //                    ?? []
        //            )
        //
        //            if let initialPlannerEvent {
        //                // Clone the dummy calendar event.
        //                event = PlannerEvent(
        //                    sortIndex: initialPlannerEvent.sortIndex
        //                )
        //            }
        //
        //            modelContext.insert(event)
        //        }
        //
        //        event.planner = planner
        //        event.title = title
        //        event.date = hasTime ? date : nil
        //
        //        let validSortIndex = generateValidPlannerEventSortIndex(
        //            for: event,
        //            in: combinedEvents + [event]  // Ensure the planner contains the event.
        //        )
        //
        //        if validSortIndex != event.sortIndex {
        //            event.sortIndex = validSortIndex
        //        }
        //
        //        do {
        //            try modelContext.save()
        //        } catch {
        //            assertionFailure("Failed to save planner event: \(error)")
        //        }
        //
        //        dismiss()
        //        handleEventChange(.planner(id: event.id, sortIndex: validSortIndex))
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

        // TODO: handle end events too
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
                id: event.eventIdentifier,
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
            hiddenCalendarIds: calendarSettings.hiddenCalendarIds
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

        // TODO: load in here
        let calendarEvents: [EKEvent] = []
            // calendarStore.timedEvents(for: planner)

        let calendarPlannerEvents =
            modelContext.synchronize(
                calendarEvents: calendarEvents,
                into: plannerEvents,
                planner: planner,
                calendarSettings: calendarSettings,
                plannerSettings: plannerSettings
            )

        return (plannerEvents + calendarPlannerEvents)
            .filter { !calendarSettings.isPlannerEventChecked($0) }
            .sorted { $0.sortIndex < $1.sortIndex }
    }

}
