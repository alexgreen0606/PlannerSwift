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

// Note: Moving this to separate file breaks ZOOM transitions of file rows.
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
    private let planner: Planner
    private let plannerSettings: PlannerSettings
    private let calendarSettings: CalendarSettings
    private let dismiss: () -> Void

    private let region: Region
    private let startOfDay: DateInRegion

    init(
        planner: Planner,
        plannerSettings: PlannerSettings,
        calendarSettings: CalendarSettings,
        dismiss: @escaping () -> Void
    ) {
        let region = planner.region(settings: plannerSettings)

        guard let startOfDay = planner.datestamp.startOfDay(in: region) else {
            fatalError("Could not get DateInRegion from: \(planner.datestamp)")
        }

        let startOfNextDay = (startOfDay + 1.days)

        // Set the query to find this date's events.
        _plannerEvents = Query(
            filter: #Predicate<PlannerEvent> {
                $0.date >= startOfDay.date && $0.date < startOfNextDay.date
            }
        )

        _plannerManager = StateObject(
            wrappedValue: ListManager<PlannerEvent>(
                isItemChecked: calendarSettings.isPlannerEventChecked
            )
        )

        self.planner = planner
        self.plannerSettings = plannerSettings
        self.calendarSettings = calendarSettings
        self.dismiss = dismiss
        self.region = region
        self.startOfDay = startOfDay
    }

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var todaystampManager: TodaystampWatcher

    @Query private var plannerEvents: [PlannerEvent]

    @State private var calendarPlannerEvents: [PlannerEvent] = []

    @StateObject private var plannerManager: ListManager<PlannerEvent>

    @State private var eventSheetContext: EventSheetContext?
    @Namespace private var namespace

    @State private var pendingScroll: PlannerEventPositionChange?
    @State private var showDeleteCheckedConfirmation = false
    @State private var showTransferSheet = false

    private var plannerType: PlannerType {
        planner.datestamp <= todaystampManager.todaystamp
            ? .pastOrPresent : .future
    }

    private var showChecked: Bool {
        plannerType == .future ? planner.showCanceled : planner.showCompleted
    }

    private var allEvents: [PlannerEvent] {
        plannerEvents + calendarPlannerEvents
    }

    private var rawCheckedEvents: [PlannerEvent] {
        allEvents.filter { calendarSettings.isPlannerEventChecked($0) }
    }

    // MARK: - Select Mode

    private var visibleEvents: [PlannerEvent] {
        if showChecked {
            return sortedOpenPlans + sortedCheckedPlans
        }

        return sortedOpenPlans
    }

    private var isAllSelected: Bool {
        plannerManager.selectedItemIds.count == visibleEvents.count
            && !visibleEvents.isEmpty
    }

    private var subtitle: String {
        if plannerManager.isSelectMode {
            let count = plannerManager.selectedItems.count
            return
                "\(count == 0 ? "No" : String(count)) plan\(count == 1 ? "" : "s") selected"
        }

        return startOfDay.dynamicSubheader
    }

    // MARK: - UI Lists

    private var sortedOpenPlans: [PlannerEvent] {
        allEvents
            .filter {
                (!(calendarSettings.isPlannerEventChecked($0))
                    && !plannerManager.newlyUncheckedIds.contains($0.id))
                    || plannerManager.newlyCheckedIds.contains($0.id)
            }
            .sorted {
                $0.sortIndex < $1.sortIndex
            }
    }

    private var sortedCheckedPlans: [PlannerEvent] {
        allEvents
            .filter {
                (calendarSettings.isPlannerEventChecked($0)
                    && !plannerManager.newlyCheckedIds.contains($0.id))
                    || plannerManager.newlyUncheckedIds.contains($0.id)
            }
            .sorted { $0.sortIndex < $1.sortIndex }
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
                    checkedFooter: plannerType.getCheckedFooter(
                        for: startOfDay
                    ),
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
                    moveItem: moveUncheckedEvent,
                    isItemChecked: calendarSettings.isPlannerEventChecked
                )
                .navigationTitle(startOfDay.dynamicHeader)
                .navigationSubtitle(subtitle)
                .toolbar {
                    topLeftToolbar
                    topRightToolbar
                    bottomToolbar(proxy)
                }
                .animateChange(from: plannerManager.isSelectMode)

                // Event Sheet
                .sheet(item: $eventSheetContext) { context in
                    EventFormView(
                        plannerEvent: context.plannerEvent,
                        calendarEvent: context.calendarEvent,
                        plannerSettings: plannerSettings,
                        calendarSettings: calendarSettings
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
                    TransferEventsFormView(
                        startOfDay: startOfDay,
                        settings: plannerSettings
                    )
                    .navigationTransition(
                        .zoom(
                            sourceID: "TRANSFER",
                            in: namespace
                        )
                    )
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
        
        // Pass the custom toggler to the planner manager.
        .task {
            plannerManager.setToggleItem(togglePlannerEvent)
        }

        // Up-to-date calendar data.
        .externalData(
            key: calendarStore.refreshKey,
            ready: true,
            load: synchronizeCalendarEvents
        )

    }

    // MARK: - Toolbars

    @ToolbarContentBuilder
    private var topLeftToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if !plannerManager.isSelectMode {
                Button("Back", systemImage: "chevron.left") {
                    dismiss()
                }
            } else {
                Button("Cancel", systemImage: "xmark") {
                    plannerManager.toggleSelectMode()
                }
            }
        }
    }

    @ToolbarContentBuilder
    private var topRightToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if !plannerManager.isSelectMode {
                Menu {
                    Button(
                        action: {
                            plannerType == .future
                                ? planner.showCanceled.toggle()
                                : planner.showCompleted.toggle()
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
                            showDeleteCheckedConfirmation = true
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
                    isPresented: $showDeleteCheckedConfirmation,
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
    }

    @ToolbarContentBuilder
    private func bottomToolbar(_ proxy: ScrollViewProxy) -> some ToolbarContent
    {
        ToolbarItemGroup(placement: .bottomBar) {
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

                    modelContext.createEvent(
                        startOfDay: startOfDay,
                        at: sortedOpenPlans.count,
                        in: sortedOpenPlans
                    )
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
    }

    // MARK: - Chips

    @ViewBuilder
    private var chipSpread: some View {
        PlannerChipSpreadView(
            planner: planner,
            startOfDay: startOfDay,
            iconMap: calendarSettings.iconMap,
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

    // MARK: - Event Rows

    @ViewBuilder
    private func startAdornment(event: PlannerEvent) -> some View {
        if let calendarEvent = event.calendarEvent,
            let calendar = calendarEvent.calendar
        {
            Image(
                systemName:
                    calendarSettings.iconMap[
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
            in: region,
            openSheet: openPlannerEventSheet,
            accentColor: accentColor.swiftUIColor
        )
    }

    // Toggle confirmation config for calendar events.
    private var toggleEventIconConfig: RowToggleConfig<PlannerEvent>? {
        switch plannerType {
        case .pastOrPresent: return nil
        case .future:
            return RowToggleConfig(
                name: "circle.slash",
                primaryColor: .red,
                secondaryColor: .secondary,
                confirmation: RowConfirmationConfig(
                    title: "Delete from calendar?",
                    message: "Hiding only affects visibility in this planner.",
                    needsConfirmation: { event in
                        event.calendarEvent != nil
                            && !calendarSettings.isPlannerEventChecked(
                                event
                            )
                    },
                    actions: [
                        ConfirmationAction(
                            title: "Hide",
                            role: nil
                        ) { event in
                            _ = calendarSettings.toggleEvent(event)
                        },

                        ConfirmationAction(
                            title: "Delete",
                            role: .destructive
                        ) { event in
                            guard let calEvent = event.calendarEvent else {
                                return
                            }

                            calendarStore.delete(event: calEvent)
                            reloadCalendar()
                        },
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
                    planner.datestamp
                ] ?? [],
                into: plannerEvents,
                planner: planner,
                calendarSettings: calendarSettings,
                plannerSettings: plannerSettings
            ) ?? calendarPlannerEvents
    }

    private func reloadCalendar() {
        calendarStore.refresh(
            hiddenCalendarIds: calendarSettings.hiddenCalendarIds
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

        modelContext.createEvent(
            startOfDay: startOfDay,
            at: finalIndex,
            in: sortedOpenPlans
        )
    }

    private func moveUncheckedEvent(from: Int, to: Int) {
        modelContext.moveEvent(
            from: from,
            to: to,
            events: sortedOpenPlans,
            calendarSettings: calendarSettings
        )
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

        // 3. Build the data from the event title.
        guard
            let (timeValue, updatedText) = event.title.separateTimeValue()
        else {
            return
        }

        guard
            let date = timeValue.toDate(
                for: planner.datestamp
            )
        else {
            return
        }

        event.title = updatedText
        event.date = date
        event.untimed = false

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
        if plannerManager.isSelectMode {
            plannerManager.toggleItem(event)
            return
        }

        eventSheetContext =
            EventSheetContext(
                plannerEvent: event,
                calendarEvent: nil
            )
    }
    
    private func togglePlannerEvent(_ event: PlannerEvent) -> Bool {
        return modelContext.togglePlannerEvent(event, calendarSettings: calendarSettings)
    }

}
