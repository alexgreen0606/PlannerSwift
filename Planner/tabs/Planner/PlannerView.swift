//
//  PlannerView.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import Contacts
import ContactsUI
import EventKit
import SwiftData
import SwiftDate
import SwiftUI

struct CalendarEventSheetContext: Identifiable {
    var event: EKEvent
    var namespace: Namespace.ID
    var contact: CNContact?

    var id: String {
        "\(String(describing: event.eventIdentifier))-\(namespace)-\(event.isAllDay)"
    }
}

struct PlannerView: View {
    private let datestamp: String
    private let closePlanner: () -> Void

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @Environment(\.modelContext) private var modelContext
    @Query private var planners: [Planner]
    @Query private var calendarSettingsList: [CalendarSettings]

    @EnvironmentObject var calendarStore: CalendarStore
    @EnvironmentObject var todaystampManager: TodaystampWatcher

    @StateObject private var plannerManager = ListManager<PlannerEvent>()

    @State private var calendarPlannerEvents: [PlannerEvent] = []
    @State private var calendarEventSheetContext: CalendarEventSheetContext?
    @Namespace private var sheetAnimation

    @State private var calendarEventToggler = CalendarEventToggler()
    @State private var scrollProxy: ScrollViewProxy?
    @State private var isDeleteCheckedConfirmationOpen = false

    // Toggle confirmation config for calendar events.
    private var toggleEventIconConfig: CustomIconConfig<PlannerEvent>? {
        switch plannerType {
        case .pastOrPresent: return nil
        case .future:
            return CustomIconConfig(
                name: "circle.slash",
                primaryColor: .red,
                secondaryColor: Color(uiColor: .secondaryLabel),
                confirmation: ConfirmationConfig(
                    title: "Delete from calendar?",
                    message: "Hiding only affects visibility in this planner.",
                    destructiveKeys: ["Delete"],
                    needsConfirmation: { event in
                        event.calendarEvent != nil
                            && !calendarEventToggler.isPlannerEventChecked(
                                event
                            )
                    },
                    actions: [
                        "Hide": { event in
                            let _ = calendarEventToggler.toggleEvent(event)
                        }
                    ],
                    destructiveActions: [
                        "Delete": { event in
                            guard let calEvent = event.calendarEvent else {
                                return
                            }

                            calendarStore.delete(event: calEvent)

                            reloadCalendar()
                        }
                    ]
                )
            )
        }
    }

    // MARK: - Swift Data

    private var calendarSettings: CalendarSettings? {
        calendarSettingsList.first
    }

    private var planner: Planner? {
        planners.first
    }

    // MARK: - Helper Variables

    private var date: Date {
        datestamp.date ?? Date()
    }

    private var plannerType: PlannerType {
        datestamp <= todaystampManager.todaystamp ? .pastOrPresent : .future
    }

    private var showChecked: Bool {
        plannerType == .future
            ? planner?.showCanceled == true : planner?.showCompleted == true
    }

    private var rawCheckedEvents: [PlannerEvent] {
        guard let planner else {
            return []
        }

        let combinedEvents = planner.events + calendarPlannerEvents

        return
            combinedEvents
            .filter {
                calendarEventToggler.isPlannerEventChecked($0)
            }
    }

    // MARK: - UI Lists

    private var sortedOpenPlans: [PlannerEvent] {
        guard let planner else {
            return []
        }

        let combinedEvents = planner.events + calendarPlannerEvents

        return
            combinedEvents
            .filter {
                (!(calendarEventToggler.isPlannerEventChecked($0))
                    && !plannerManager.newlyUncheckedIds.contains($0.id))
                    || plannerManager.newlyCheckedIds.contains($0.id)
            }
            .sorted {
                $0.sortIndex < $1.sortIndex
            }
    }

    private var sortedCheckedPlans: [PlannerEvent] {
        guard let planner else {
            return []
        }

        let combinedEvents = planner.events + calendarPlannerEvents

        return
            combinedEvents
            .filter {
                (calendarEventToggler.isPlannerEventChecked($0)
                    && !plannerManager.newlyCheckedIds.contains($0.id))
                    || plannerManager.newlyUncheckedIds.contains($0.id)
            }
            .sorted { $0.sortIndex < $1.sortIndex }
    }

    // Set the query to find this date's planner.
    init(datestamp: String, closePlanner: @escaping () -> Void) {
        self.datestamp = datestamp
        self.closePlanner = closePlanner

        _planners = Query(
            filter: #Predicate<Planner> {
                $0.datestamp == datestamp
            }
        )
    }

    var body: some View {
        ScrollViewReader { proxy in
            SortableListView<
                PlannerEvent, AnyView, PlannerChipSpreadView
            >(
                uncheckedItems: sortedOpenPlans,
                checkedItems: sortedCheckedPlans,
                showChecked: showChecked,
                floatingInfo: PlannerChipSpreadView(
                    datestamp: datestamp,
                    events: calendarStore.allDayEventsByDatestamp[
                        datestamp
                    ] ?? [],
                    showCountdown: true,
                    showWeather: true,
                    iconMap: calendarSettings?.iconMap ?? [:],
                    animation: sheetAnimation,
                    openCalendarEventSheet: openCalendarEventSheet
                ),
                customToggleConfig: toggleEventIconConfig,
                checkedHeader: plannerType.checkedHeader,
                checkedFooter: plannerType.getCheckedFooter(for: datestamp),
                emptyUncheckedLabel: "No plans",
                emptyCheckedLabel: plannerType.emptyCheckedLabel,
                tint: accentColor.swiftUIColor,
                getEndAdornment: { event in
                    AnyView(
                        event.timeValueView(
                            for: datestamp,
                            openPlannerEventSheet: openPlannerEventSheet,
                            openCalendarEventSheet: openCalendarEventSheet,
                            animation: sheetAnimation,
                            accentColor: accentColor.swiftUIColor
                        )
                    )
                },
                createItem: createEvent,
                handleTitleChange: handleEventTitleChange,
                moveItem: handleMoveUncheckedEvent,
                isItemChecked: calendarEventToggler.isPlannerEventChecked
            )
            .environmentObject(plannerManager)
            .navigationTitle(date.dynamicHeader)
            .navigationSubtitle(date.dynamicSubheader)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Back", systemImage: "chevron.down") {
                        closePlanner()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(
                            action: {
                                plannerType == .future
                                    ? planner?.showCanceled.toggle()
                                    : planner?.showCompleted.toggle()
                            },
                            label: {
                                Text(
                                    plannerType.getToggleVisibilityLabel(
                                        showChecked
                                    )
                                )
                                Image(
                                    systemName: showChecked
                                        ? "eye.slash" : "eye"
                                )
                            }
                        )

                        Menu {
                            Button(role: .destructive) {
                                isDeleteCheckedConfirmationOpen = true
                            } label: {
                                Text(plannerType.deleteCheckedLabel)
                                Image(systemName: "trash")
                            }
                            .disabled(rawCheckedEvents.isEmpty)

                        } label: {
                            Text("Delete options")
                            Image(systemName: "trash")
                        }

                    } label: {
                        Image(systemName: "ellipsis")
                    }
                    .confirmationDialog(
                        plannerType.deleteCheckedConfirmationTitle,
                        isPresented: $isDeleteCheckedConfirmationOpen,
                        titleVisibility: .visible
                    ) {
                        Button("Confirm", role: .destructive) {
                            deleteAllCheckedEvents()
                        }
                    } message: {
                        Text(
                            "This action is irreversible."
                        )
                    }
                }

                ToolbarItemGroup(placement: .bottomBar) {
                    Spacer()

                    Button("Add", systemImage: "plus") {
                        if let last = sortedOpenPlans.last, last.title.isEmpty {
                            return
                        }

                        scrollProxy?.slideTo("UNCHECKED", at: .bottom)
                        createEvent(at: sortedOpenPlans.count)
                    }
                    .tint(accentColor.swiftUIColor)
                }
            }

            .onAppear {
                scrollProxy = proxy
            }
        }
        // Slide to the checked items when the user marks them visible.
        .onChange(of: showChecked) { _, newShowChecked in
            if newShowChecked {
                scrollProxy?.slideTo("CHECKED", at: .top)
            }
        }
        .task {
            modelContext.ensureCalendarSettings(
                settings: calendarSettingsList
            )
            
            modelContext.ensurePlanner(
                planners: planners,
                datestamp: datestamp
            )

            calendarStore.ensureCalendarEvents(
                for: datestamp,
                hiddenCalendarIds: calendarSettings!.hiddenCalendarIds
            )

            synchronizeCalendarEvents()

            // Setup the calendar event handler.
            calendarEventToggler.calendarSettings = calendarSettings

            plannerManager.setToggleItem(calendarEventToggler.toggleEvent)
            plannerManager.setStatusChecker(
                calendarEventToggler.isPlannerEventChecked
            )
        }
        // Rebuild the planner when the calendar events change.
        .onChange(of: calendarStore.refreshKey) { _, newKey in
            synchronizeCalendarEvents()
        }
        .sheet(item: $calendarEventSheetContext) { context in
            Group {
                if let contact = context.contact {
                    ContactFormView(contact: contact)
                } else {
                    switch context.event.calendar.allowsContentModifications {
                    case true:
                        EditCalendarEventFormView(
                            event: context.event,
                            eventStore: calendarStore.ekEventStore
                        ) { action, updatedEvent in
                            reloadCalendar()
                            calendarEventSheetContext = nil
                        }

                    case false:
                        ViewCalendarEventFormView(event: context.event)
                            .presentationDetents([.height(340)])
                    }
                }
            }
            .tint(accentColor.swiftUIColor)
            .ignoresSafeArea()
            .navigationTransition(
                .zoom(
                    sourceID: context.id,
                    in: context.namespace
                )
            )
        }
    }

    // MARK: - Data Handlers

    private func synchronizeCalendarEvents() {
        calendarPlannerEvents =
            modelContext.synchronize(
                calendarEvents: calendarStore.singleDayEventsByDatestamp[
                    datestamp
                ] ?? [],
                into: planner,
                with: calendarSettings
            ) ?? calendarPlannerEvents
    }

    private func reloadCalendar() {
        calendarStore.refresh(
            hiddenCalendarIds: calendarSettings?
                .hiddenCalendarIds ?? []
        )
    }

    // MARK: - List Actions

    private func createEvent(
        near baseId: PersistentIdentifier?,
        offset: Int = 0
    ) {
        guard
            let baseIndex = sortedOpenPlans.firstIndex(where: {
                $0.id == baseId
            })
        else {
            return
        }

        let finalIndex = baseIndex + offset

        // Don't create the new item if it is next to an empty item.
        let upperEvent = finalIndex > 0 ? sortedOpenPlans[finalIndex - 1] : nil
        let lowerEvent =
            finalIndex < sortedOpenPlans.count
            ? sortedOpenPlans[finalIndex] : nil
        if let upper = upperEvent, upper.title.isEmpty {
            return
        }
        if let lower = lowerEvent, lower.title.isEmpty {
            return
        }

        createEvent(at: finalIndex)
    }

    private func createEvent(at index: Int) {
        guard let planner = planner else { return }
        let sortIndex = generateSortIndex(index: index, items: sortedOpenPlans)
        let newEvent = PlannerEvent(sortIndex: sortIndex, planner: planner)

        modelContext.insert(newEvent)
        try! modelContext.save()
    }

    private func handleMoveUncheckedEvent(from: Int, to: Int) {
        guard from != to else { return }

        // 1: Force-save the event to its new position.
        let movedEvent = sortedOpenPlans[from]
        let eventsWithoutEvent = sortedOpenPlans.filter {
            $0.id != movedEvent.id
        }
        let newSortIndex = generateSortIndex(
            index: to,
            items: eventsWithoutEvent
        )
        movedEvent.sortIndex = newSortIndex

        // Save the calendar event position.
        if movedEvent.calendarEvent != nil && calendarSettings != nil {
            calendarSettings!.sortIndexMap[
                movedEvent.calendarEvent!.eventIdentifier
            ] = movedEvent.sortIndex
        }

        try! modelContext.save()

        // 2: After UI settles, validate correct chronological insertion.
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_000_000_000)  // 1 sec

            let validSortIndex = generateValidPlannerEventSortIndex(
                for: movedEvent,
                in: sortedOpenPlans
            )
            if validSortIndex != newSortIndex {
                movedEvent.sortIndex = validSortIndex

                // Save the calendar event position.
                if movedEvent.calendarEvent != nil
                    && calendarSettings != nil
                {
                    calendarSettings!.sortIndexMap[
                        movedEvent.calendarEvent!.eventIdentifier
                    ] = movedEvent.sortIndex
                }

                try! modelContext.save()
            }
        }
    }

    private func handleEventTitleChange(event: PlannerEvent) {
        // 1. TODO: Recurring event: delete and clone event.

        // 2. Update the device calendar with the new title.
        guard event.calendarEvent == nil else {
            event.calendarEvent!.title = event.title
            try! calendarStore.ekEventStore.save(
                event.calendarEvent!,
                span: .thisEvent
            )
            return
        }

        guard let datestamp = event.planner?.datestamp else { return }

        // 3. Build the data from the event title.
        guard
            let (timeValue, updatedText) = event.title.separateTimeValue()
        else {
            return
        }

        guard
            let date = timeValue.toDate(
                for: datestamp
            )
        else {
            return
        }

        event.title = updatedText
        event.date = date

        // 4. Validate sort order.
        let newSortIndex = generateValidPlannerEventSortIndex(
            for: event,
            in: sortedOpenPlans
        )

        guard newSortIndex != event.sortIndex else {
            try? modelContext.save()
            return
        }

        event.sortIndex = newSortIndex
        scrollProxy?.slideTo(event.id, at: .bottom, withDelay: .seconds(1))

        try? modelContext.save()
    }

    // MARK: - Sheet Handlers

    private func openPlannerEventSheet(
        for event: PlannerEvent
    ) {
        // TODO: open custom sheet
    }

    private func openCalendarEventSheet(
        for event: EKEvent
    ) {
        // Open the contact for birthday events.
        var contact: CNContact? = nil
        if event.calendar.type == .birthday,
            let contactId = event.birthdayContactIdentifier
        {

            let store = CNContactStore()

            do {
                contact = try store.unifiedContact(
                    withIdentifier: contactId,
                    keysToFetch: [
                        CNContactViewController.descriptorForRequiredKeys()
                    ] as [CNKeyDescriptor]
                )
            } catch {
                assertionFailure("Failed to fetch birthday contact: \(error)")
            }
        }

        calendarEventSheetContext = CalendarEventSheetContext(
            event: event,
            namespace: sheetAnimation,
            contact: contact
        )
    }

    // MARK: - Overflow Actions

    private func deleteAllCheckedEvents() {

        rawCheckedEvents
            .forEach {
                guard let calendarEvent = $0.calendarEvent else {
                    modelContext.delete($0)
                    return
                }

                calendarStore.delete(event: calendarEvent)
            }

        reloadCalendar()

        do {
            try modelContext.save()
        } catch {
            assertionFailure(
                "Failed to delete checked events: \(error)"
            )
        }
    }
}
