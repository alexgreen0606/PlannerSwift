//
//  PlannerView.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import EventKit
import SwiftData
import SwiftDate
import SwiftUI

struct EventSheetContext: Identifiable {
    var plannerEvent: PlannerEvent?
    var calendarEvent: EKEvent?

    var id: String {
        if let plannerEventId = plannerEvent?.id {
            return "\(plannerEventId)"
        }

        if let calEvent = calendarEvent {
            return calEvent.transitionId
        }

        return "FALLBACK_NO_EVENT"
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
    @State private var calendarEventToggler = CalendarEventToggler()

    @State private var eventSheetContext: EventSheetContext?
    @Namespace private var namespace

    @State private var calendarPlannerEvents: [PlannerEvent] = []
    @State private var isDeleteCheckedConfirmationOpen = false
    @State private var showTransferSheet = false
    @State private var pendingScroll: PlannerEventPositionChange?

    private var calendarSettings: CalendarSettings? {
        calendarSettingsList.first
    }

    private var planner: Planner? {
        planners.first
    }

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

    private var visibleEvents: [PlannerEvent] {
        var allVisibleItems = sortedOpenPlans

        if planner?.showCompleted == true {
            allVisibleItems.append(
                contentsOf: sortedCheckedPlans
            )
        }

        return allVisibleItems
    }

    private var isAllSelected: Bool {
        plannerManager.selectedItemIds.count == visibleEvents.count
            && !visibleEvents.isEmpty
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

    init(datestamp: String, closePlanner: @escaping () -> Void) {
        self.datestamp = datestamp
        self.closePlanner = closePlanner

        // Set the query to find this date's planner.
        _planners = Query(
            filter: #Predicate<Planner> {
                $0.datestamp == datestamp
            }
        )
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                SortableListView(
                    uncheckedItems: sortedOpenPlans,
                    checkedItems: sortedCheckedPlans,
                    showChecked: showChecked,
                    floatingInfo: chipSpread,
                    customToggleConfig: toggleEventIconConfig,
                    checkedHeader: plannerType.checkedHeader,
                    checkedFooter: plannerType.getCheckedFooter(for: datestamp),
                    emptyUncheckedLabel: "No plans",
                    emptyCheckedLabel: plannerType.emptyCheckedLabel,
                    namespace: namespace,
                    tint: eventTint,
                    toolbarIcons: ["clock"],
                    tapToolbar: handleToolbarTap,
                    startAdornment: startAdornment,
                    endAdornment: endAdornment,
                    proxy: proxy,
                    createItem: createEvent,
                    handleTitleChange: handleEventTitleChange,
                    moveItem: handleMoveUncheckedEvent,
                    isItemChecked: calendarEventToggler.isPlannerEventChecked
                )
                .navigationTitle(date.dynamicHeader)
                .navigationSubtitle(date.dynamicSubheader)
                .toolbar {
                    topLeftToolbar
                    topRightToolbar
                    bottomToolbar(proxy)
                }
                
                // Event Sheet
                .sheet(item: $eventSheetContext) { context in
                    EventFormView(
                        plannerEvent: context.plannerEvent,
                        calendarEvent: context.calendarEvent
                    ) { change in
                        pendingScroll = change
                    }
                    .navigationTransition(
                        .zoom(
                            sourceID: context.id,
                            in: namespace
                        )
                    )
                }
                
                // Event Sheet
                .sheet(isPresented: $showTransferSheet) {
                    if let planner {
                        TransferEventsFormView(
                            sourcePlanner: planner
                        )
                        .navigationTransition(
                            .zoom(
                                sourceID: "TRANSFER",
                                in: namespace
                            )
                        )
                    }
                }

                // Slide to modified events once the UI has settled.
                .onChange(of: sortedOpenPlans.map(\.id)) { _, _ in
                    attemptScrollToEvent(
                        proxy: proxy
                    )
                }
                .onChange(of: pendingScroll) { _, _ in
                    attemptScrollToEvent(
                        proxy: proxy
                    )
                }
            }
        }
        .environmentObject(plannerManager)

        // Initialize data.
        .task {
            modelContext.ensurePlanner(
                planners: planners,
                datestamp: datestamp
            )

            modelContext.ensureCalendarSettings(
                settings: calendarSettingsList
            )

            calendarStore.ensureCalendarEvents(
                for: datestamp,
                hiddenCalendarIds: calendarSettings!.hiddenCalendarIds
            )

            // Setup the planner managers.
            calendarEventToggler.calendarSettings = calendarSettings
            plannerManager.setToggleItem(calendarEventToggler.toggleEvent)
            plannerManager.setStatusChecker(
                calendarEventToggler.isPlannerEventChecked
            )
        }

        // Up-to-date calendar data.
        .externalData(
            key: calendarStore.refreshKey,
            ready: planner != nil && calendarSettings != nil,
            load: synchronizeCalendarEvents
        )

    }

    // MARK: - Toolbars

    @ToolbarContentBuilder
    private var topLeftToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            Group {
                if !plannerManager.isSelectMode {
                    Button("Back", systemImage: "chevron.left") {
                        closePlanner()
                    }
                } else {
                    Button("Cancel", systemImage: "xmark") {
                        plannerManager.toggleSelectMode()
                    }
                }
            }
            .animateChange(from: plannerManager.isSelectMode)
        }
    }

    @ToolbarContentBuilder
    private var topRightToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Group {
                if !plannerManager.isSelectMode {
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

                        Button {
                            plannerManager.toggleSelectMode()
                        } label: {
                            Image(systemName: "checkmark.circle")
                            Text("Select events")
                                .fontWeight(.semibold)
                        }
                        .disabled(visibleEvents.isEmpty)

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
                            "Calendar events will not be deleted. This action is irreversible."
                        )
                    }
                } else {
                    Button {
                        if isAllSelected {
                            plannerManager.selectedItemIds = []
                            plannerManager.selectedItems = []
                        } else {
                            plannerManager.selectedItems = visibleEvents
                            plannerManager.selectedItemIds = Set(
                                visibleEvents.map { $0.id }
                            )
                        }
                    } label: {
                        Text(isAllSelected ? "Deselect All" : "Select All")
                            .fontWeight(.semibold)
                    }
                    .disabled(visibleEvents.isEmpty)
                }
            }
            .animateChange(from: plannerManager.isSelectMode)
        }
    }

    @ToolbarContentBuilder
    private func bottomToolbar(_ proxy: ScrollViewProxy) -> some ToolbarContent
    {
        ToolbarItemGroup(placement: .bottomBar) {
            Group {
                if !plannerManager.isSelectMode {
                    Spacer()

                    Button("Add", systemImage: "plus") {
                        if let last = sortedOpenPlans.last,
                            last.title.isEmpty
                        {
                            return
                        }

                        DispatchQueue.main.async {
                            withAnimation {
                                proxy.scrollTo("UNCHECKED", anchor: .bottom)
                            }
                        }

                        createEvent(at: sortedOpenPlans.count)
                    }
                    .tint(accentColor.swiftUIColor)
                } else {
                    DeleteSelectedButtonView(
                        itemsLabel: "events",
                        disabled: plannerManager.selectedItemIds.isEmpty,
                        warningMessage:
                            "Calendar and planner events will be lost."
                    ) {
                        let selectedEvents = plannerManager.selectedItems

                        var plannerOnlyEvents: [PlannerEvent] = []

                        for event in selectedEvents {
                            if let calEvent = event.calendarEvent {
                                // Delete from device calendar.
                                calendarStore.delete(event: calEvent)
                            } else {
                                plannerOnlyEvents.append(event)
                            }
                        }

                        // Delete non-calendar events.
                        if !plannerOnlyEvents.isEmpty {
                            modelContext.deletePlannerEvents(plannerOnlyEvents)
                        }

                        reloadCalendar()

                        DispatchQueue.main.asyncAfter(
                            deadline: .now() + .milliseconds(750)
                        ) {
                            withAnimation {
                                plannerManager.toggleSelectMode()
                            }
                        }
                    }

                    Spacer()

                    Button(
                        "Transfer",
                        systemImage: "arrow.forward.folder"
                    ) {
                        showTransferSheet = true
                    }
                    .disabled(plannerManager.selectedItemIds.isEmpty)
                    .matchedTransitionSource(
                        id: "TRANSFER",
                        in: namespace
                    )
                }
            }
            .animateChange(from: plannerManager.isSelectMode)
        }
    }

    // MARK: - Chips

    @ViewBuilder
    private var chipSpread: some View {
        if let planner {
            PlannerChipSpreadView(
                planner: planner,
                iconMap: calendarSettings?.iconMap ?? [:],
                namespace: namespace,
                openCalendarEventSheet: { calEvent in
                    eventSheetContext =
                        EventSheetContext(
                            plannerEvent: nil,
                            calendarEvent: calEvent
                        )
                }
            )
        }
    }

    // MARK: - Event Rows

    @ViewBuilder
    private func startAdornment(event: PlannerEvent) -> some View {
        if let calendarEvent = event.calendarEvent,
            let calendar = calendarEvent.calendar
        {
            Image(
                systemName:
                    calendarSettings?.iconMap[
                        calendar.calendarIdentifier
                    ] ?? calendar.iconName
            )
            .foregroundStyle(calendar.color)
            .padding(.trailing, 6)
            .contentShape(Rectangle())
            .onTapGesture {
                openPlannerEventSheet(event)
            }
        }
    }

    @ViewBuilder
    private func endAdornment(event: PlannerEvent) -> some View {
        event.timeValueView(
            for: datestamp,
            openSheet: openPlannerEventSheet,
            accentColor: accentColor.swiftUIColor
        )
    }

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
                movedEvent.calendarEvent!.calendarItemExternalIdentifier
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
                        movedEvent.calendarEvent!.calendarItemExternalIdentifier
                    ] = movedEvent.sortIndex
                }

                try! modelContext.save()
            }
        }
    }

    private func handleEventTitleChange(event: PlannerEvent) {
        // 1. TODO: Handle recurring events here

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
            do {
                try modelContext.save()
            } catch {
                assertionFailure(
                    "Failed to save new item after time smart-detect: \(error)"
                )
            }
            return
        }

        event.sortIndex = newSortIndex
        pendingScroll = .planner(id: event.id, sortIndex: newSortIndex)

        do {
            try modelContext.save()
        } catch {
            assertionFailure(
                "Failed to save new item after time smart-detect: \(error)"
            )
        }
    }

    // MARK: - Overflow Actions

    private func deleteAllCheckedEvents() {
        modelContext.deletePlannerEvents(rawCheckedEvents)
    }

    // MARK: - Helpers

    private func attemptScrollToEvent(
        proxy: ScrollViewProxy
    ) {
        guard let pending = pendingScroll, pending.isScrollable else {
            return
        }

        let targetEvent: PlannerEvent? = {
            if let plannerId = pending.plannerId {
                return sortedOpenPlans.first(where: { $0.id == plannerId })
            }

            if let calendarId = pending.calendarId {
                return sortedOpenPlans.first(
                    where: { $0.calendarEvent?.eventIdentifier == calendarId }
                )
            }

            return nil
        }()

        guard
            let event = targetEvent,
            let targetSortIndex = pending.targetSortIndex,
            event.sortIndex == targetSortIndex
        else {
            // List not ready yet. Wait for next change.
            return
        }

        DispatchQueue.main.async {
            withAnimation {
                proxy.scrollTo("\(event.id)", anchor: .center)
            }
        }

        pendingScroll = nil
    }

    private func eventTint(event: PlannerEvent) -> Color {
        event.tint(accentColor: accentColor)
    }

    private func handleToolbarTap(icon: String, event: PlannerEvent) {
        openPlannerEventSheet(event)
    }

    private func openPlannerEventSheet(_ event: PlannerEvent) {
        eventSheetContext =
            EventSheetContext(
                plannerEvent: event,
                calendarEvent: nil
            )
    }

}
