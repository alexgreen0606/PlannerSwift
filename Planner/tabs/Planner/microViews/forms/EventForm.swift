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
import SwiftUI

struct EventFormView: View {
    private let initialPlannerEvent: PlannerEvent?
    private let initialCalendarEvent: EKEvent?
    private let handleEventChange: (PlannerEventPositionChange) -> Void

    // Overrides all other behavior in this sheet and displays the Contact form.
    private let contact: CNContact?

    @AppStorage("keepPastPlansDuration") private var keepPastPlansDuration:
        KeepPastPlansDuration =
            KeepPastPlansDuration.oneMonth

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query private var calendarSettingsList: [CalendarSettings]

    @EnvironmentObject var calendarStore: CalendarStore
    @EnvironmentObject var todaystampWatcher: TodaystampWatcher

    @State private var calendarEventToggler = CalendarEventToggler()

    @State private var draftCalendarEvent: EKEvent?
    @State private var selectedDetent: PresentationDetent = .height(340)

    @State private var title: String
    @State private var date: Date
    @State private var hasTime: Bool

    private var calendarSettings: CalendarSettings? {
        calendarSettingsList.first
    }

    private var isValid: Bool {
        !title.isEmpty
            && (date != initialPlannerEvent?.date
                || title != initialPlannerEvent?.title
                || draftCalendarEvent
                    != initialPlannerEvent?.calendarEvent)
    }

    private var isCreateForm: Bool {
        initialPlannerEvent == nil && initialCalendarEvent == nil
    }

    init(
        plannerEvent: PlannerEvent?,
        calendarEvent: EKEvent?,
        handleEventChange: @escaping (PlannerEventPositionChange) -> Void
    ) {
        self.initialPlannerEvent = plannerEvent
        self.initialCalendarEvent = plannerEvent?.calendarEvent ?? calendarEvent
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

            if let time = plannerEvent.date {
                date = time
                hasTime = true
            } else if let target = plannerEvent.planner?.datestamp.date {
                date = target
                hasTime = false
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

        _title = State(initialValue: title)
        _date = State(initialValue: date)
        _hasTime = State(initialValue: hasTime)
        self.contact = contact
    }

    var body: some View {
        Group {
            if let contact {
                ContactFormView(contact: contact)
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
        .task {
            modelContext.ensureCalendarSettings(
                settings: calendarSettingsList
            )

            calendarEventToggler.calendarSettings = calendarSettings
        }
    }

    private var plannerEventForm: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $title)
                        .textInputAutocapitalization(.words)
                }
                .listSectionMargins(.top, 0)

                DatePicker(
                    "Date",
                    selection: $date,
                    in: keepPastPlansDuration
                        .cutoffDate...todaystampWatcher
                        .maxCalendarDate,
                    displayedComponents: hasTime
                        ? [.date, .hourAndMinute] : .date
                )

                Toggle("Schedule a time", isOn: $hasTime)
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

    private func calendarEventForm(for event: EKEvent) -> some View {
        Group {
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

                        syncLocalCalendarData()
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
                    .tint(accentColor.swiftUIColor)
                    .ignoresSafeArea()
            }
        }
    }

    private var plannerEventTopRightToolbar: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button("Save", systemImage: "checkmark") {
                savePlannerEvent()
            }
            .disabled(!isValid)
            .tint(accentColor.swiftUIColor)
        }
    }

    private var plannerEventBottomToolbar: some ToolbarContent {
        Group {
            if !calendarStore.accessDenied {
                ToolbarItem(placement: .bottomBar) {
                    Button {

                        // Create a new calendar event to represent the form values.
                        let event = EKEvent(
                            eventStore: calendarStore.ekEventStore
                        )
                        event.calendar =
                            calendarStore.ekEventStore
                            .defaultCalendarForNewEvents
                        event.title = title
                        event.startDate = date
                        event.endDate = Calendar.current.date(
                            byAdding: .hour,
                            value: 1,
                            to: date
                        )

                        draftCalendarEvent = event
                        selectedDetent = .height(2600)
                    } label: {
                        HStack(alignment: .center) {
                            Image(systemName: "calendar.badge.plus")
                            Text("Add to calendar")
                        }
                    }
                    .tint(accentColor.swiftUIColor)
                }
                .sharedBackgroundVisibility(.hidden)
            }
        }
    }

    private var calendarEventBottomToolbar: some ToolbarContent {
        ToolbarItem(placement: .bottomBar) {
            Button {
                guard let calEvent = draftCalendarEvent else { return }

                title = calEvent.title
                date = calEvent.startDate
                hasTime = true

                draftCalendarEvent = nil
                selectedDetent = .height(340)
            } label: {
                HStack(alignment: .center) {
                    Image(systemName: "calendar.badge.minus")
                    Text("Remove from calendar")
                }
            }
            .tint(accentColor.swiftUIColor)
        }
        .sharedBackgroundVisibility(.hidden)
    }

    private func savePlannerEvent() {
        let targetDatestamp = date.datestamp
        let hasEventMoved =
            initialPlannerEvent?.planner?.datestamp != targetDatestamp

        let planner = loadPlanner(for: targetDatestamp)
        let combinedEvents = getPlannerEvents(for: planner)
        let bottomSortIndex = (combinedEvents.last?.sortIndex ?? 0) + 8.0

        var event =
            initialPlannerEvent ?? PlannerEvent(sortIndex: bottomSortIndex)
        if hasEventMoved && initialPlannerEvent != nil {
            // Transfered events get placed at the bottom of their new planner.
            event.sortIndex = bottomSortIndex
        }

        // Delete the stale calendar event if one exists.
        if let calEvent = initialCalendarEvent {

            calendarStore.delete(event: calEvent)
            calendarStore.refresh(
                hiddenCalendarIds: calendarSettings?.hiddenCalendarIds
                    ?? []
            )

            if let initialPlannerEvent {
                // Clone the dummy calendar event.
                event = PlannerEvent(
                    sortIndex: initialPlannerEvent.sortIndex
                )
            }

            modelContext.insert(event)
        }

        event.planner = planner
        event.title = title
        event.date = hasTime ? date : nil

        let validSortIndex = generateValidPlannerEventSortIndex(
            for: event,
            in: combinedEvents + [event]  // Ensure the planner contains the event.
        )

        if validSortIndex != event.sortIndex {
            event.sortIndex = validSortIndex
        }

        do {
            try modelContext.save()
        } catch {
            assertionFailure("Failed to save planner event: \(error)")
        }

        dismiss()
        handleEventChange(.planner(id: event.id, sortIndex: validSortIndex))
    }

    private func handleCalendarEventChange(_ event: EKEvent) {
        syncLocalCalendarData()

        let targetDatestamp = event.startDate.datestamp
        let planner = loadPlanner(for: targetDatestamp)

        // Rebuild planner events using the same pipeline as the list
        let rebuiltEvents = getPlannerEvents(for: planner)

        guard
            let plannerEvent = rebuiltEvents.first(
                where: {
                    $0.calendarEvent?.calendarItemExternalIdentifier
                        == event.calendarItemExternalIdentifier
                }
            )
        else {
            assertionFailure(
                "Saved calendar event not found in rebuilt planner."
            )
            dismiss()
            return
        }

        let finalSortIndex = plannerEvent.sortIndex

        dismiss()

        handleEventChange(
            .calendar(
                id: event.eventIdentifier,
                sortIndex: finalSortIndex
            )
        )
    }

    // Deletes stale planner event and reloads the calendar.
    private func syncLocalCalendarData() {
        if let initialPlannerEvent, initialPlannerEvent.calendarEvent == nil {
            modelContext.delete(initialPlannerEvent)
        }

        calendarStore.refresh(
            hiddenCalendarIds: calendarSettings?.hiddenCalendarIds
                ?? []
        )
    }

    private func loadPlanner(
        for datestamp: String
    ) -> Planner {

        let descriptor = FetchDescriptor<Planner>(
            predicate: #Predicate<Planner> { planner in
                planner.datestamp == datestamp
            }
        )

        do {
            let planners = try modelContext.fetch(descriptor)

            guard let planner = planners.first else {
                return Planner(datestamp: datestamp)
            }

            return planner
        } catch {
            assertionFailure("Failed to load in the planner: \(error)")
            return Planner(datestamp: datestamp)
        }
    }

    private func getPlannerEvents(
        for planner: Planner
    ) -> [PlannerEvent] {
        let calendarEvents =
            calendarStore.singleDayEventsByDatestamp[planner.datestamp] ?? []

        let calendarPlannerEvents =
            modelContext.synchronize(
                calendarEvents: calendarEvents,
                into: planner,
                with: calendarSettings
            ) ?? []

        return (planner.events + calendarPlannerEvents)
            .filter { !calendarEventToggler.isPlannerEventChecked($0) }
            .sorted { $0.sortIndex < $1.sortIndex }
    }

}
