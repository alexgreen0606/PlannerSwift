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
        if let plannerEventId = plannerEvent?.stableId {
            return "\(plannerEventId)"
        }

        if let calEvent = calendarEvent {
            return calEvent.transitionId
        }

        return "FALLBACK_NO_EVENT"
    }
}

struct ExpandedPlannerView: View {
    private let planner: Planner
    private let plannerStartOfDay: DateInRegion
    private let plannerLocation: Location?
    private let storageEvents: [PlannerEvent]
    private let allSortedPlannerEvents: [PlannerEvent]
    private let calendarData: PlannerCalendarData
    private let settings: PlannerSettings

    init(
        planner: Planner,
        plannerStartOfDay: DateInRegion,
        plannerLocation: Location?,
        storageEvents: [PlannerEvent],
        allSortedPlannerEvents: [PlannerEvent],
        calendarData: PlannerCalendarData,
        settings: PlannerSettings
    ) {
        self.planner = planner
        self.plannerStartOfDay = plannerStartOfDay
        self.plannerLocation = plannerLocation
        self.storageEvents = storageEvents
        self.allSortedPlannerEvents = allSortedPlannerEvents
        self.calendarData = calendarData
        self.settings = settings

        _plannerManager = StateObject(
            wrappedValue: ListManager<PlannerEvent>(
                isItemChecked: settings.isPlannerEventChecked
            )
        )

    }

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var todaystampManager: TodaystampWatcher
    @EnvironmentObject private var deviceLocationManager: DeviceLocationManager

    @StateObject private var plannerManager: ListManager<PlannerEvent>

    @State private var eventSheetContext: EventSheetContext?
    @Namespace private var namespace

    @State private var showDeleteCheckedConfirmation = false
    @State private var showTransferSheet = false

    private var plannerType: PlannerType {
        planner.datestamp <= todaystampManager.todaystamp
            ? .pastOrPresent : .future
    }

    private var showChecked: Bool {
        plannerType == .future ? planner.showCanceled : planner.showCompleted
    }

    private var allDayEvents: [EKEvent] {
        calendarData.allDayEvents
    }

    private var rawCheckedEvents: [PlannerEvent] {
        allSortedPlannerEvents.filter { settings.isPlannerEventChecked($0) }
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

        return plannerStartOfDay.dynamicSubheader
    }

    // MARK: - UI Lists

    private var sortedOpenPlans: [PlannerEvent] {
        allSortedPlannerEvents
            .filter {
                (!(settings.isPlannerEventChecked($0))
                    && !plannerManager.newlyUncheckedIds.contains($0.stableId))
                    || plannerManager.newlyCheckedIds.contains($0.stableId)
            }
    }

    private var sortedCheckedPlans: [PlannerEvent] {
        allSortedPlannerEvents
            .filter {
                (settings.isPlannerEventChecked($0)
                    && !plannerManager.newlyCheckedIds.contains($0.stableId))
                    || plannerManager.newlyUncheckedIds.contains($0.stableId)
            }
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { scrollProxy in
                SortableListView(
                    uncheckedItems: sortedOpenPlans,
                    checkedItems: sortedCheckedPlans,
                    showChecked: showChecked,
                    floatingInfo: chipSpread,
                    customToggleConfig: toggleEventIconConfig,
                    checkedHeader: plannerType.checkedHeader,
                    checkedFooter: plannerType.getCheckedFooter(
                        for: plannerStartOfDay
                    ),
                    emptyUncheckedLabel: "No plans",
                    emptyCheckedLabel: plannerType.emptyCheckedLabel,
                    namespace: namespace,
                    tint: eventTint,
                    toolbarIcons: ["clock"],
                    tapToolbar: handleToolbarTap,
                    leftAdornment: leftAdornment,
                    rightAdornment: rightAdornment,
                    bottomAdornment: bottomAdornment,
                    scrollProxy: scrollProxy,
                    createItem: createEvent,
                    handleTitleChange: handleEventTitleChange,
                    moveItem: moveUncheckedEvent,
                    isItemChecked: settings.isPlannerEventChecked
                )
                .navigationTitle(plannerStartOfDay.dynamicHeader)
                .navigationSubtitle(subtitle)
                .toolbar {
                    topLeftToolbar
                    topRightToolbar
                    bottomToolbar(scrollProxy: scrollProxy)
                }
                .animateSynchronousAction(from: plannerManager.isSelectMode)
            }
        }

        // Event Sheet
        .sheet(item: $eventSheetContext) { context in
            EventFormView(
                sourcePlanner: planner,
                plannerEvent: context.plannerEvent,
                calendarEvent: context.calendarEvent,
                settings: settings,
            ) {
               // TODO: show transfer snackbar
            }
            .id(context.id)
            .navigationTransition(
                .zoom(
                    sourceID: context.id,
                    in: namespace
                )
            )
            .onDisappear {
                plannerManager.protectedId = nil
            }
        }

        // Transfer Event Sheet
        .sheet(isPresented: $showTransferSheet) {
            TransferEventsFormView(
                startOfDay: plannerStartOfDay,
                settings: settings
            )
            .navigationTransition(
                .zoom(
                    sourceID: IDConstants.TRANSFER_BUTTON,
                    in: namespace
                )
            )
        }

        // Pass the custom toggler to the planner manager.
        .onAppear {
            plannerManager.setToggleItem(togglePlannerEvent)
        }
        
        .environmentObject(plannerManager)

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
                Button(
                    "Cancel",
                    systemImage: "xmark",
                    action: plannerManager.toggleSelectMode
                )
                // Note: This fixes a bug where opening select mode while a keyboard is open causes this button to
                // appear tinted as the accent color.
                .tint(Color.label)
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
                    plannerManager.toggleSelectAll(visibleItems: visibleEvents)
                } label: {
                    Text(isAllSelected ? "Deselect All" : "Select All")
                        .fontWeight(.semibold)
                }
                .disabled(visibleEvents.isEmpty)
            }
        }
    }

    @ToolbarContentBuilder
    private func bottomToolbar(scrollProxy: ScrollViewProxy)
        -> some ToolbarContent
    {
        ToolbarItemGroup(placement: .bottomBar) {
            if !plannerManager.isSelectMode {
                Spacer()

                Button("Add", systemImage: "plus") {
                    createLowerEvent(scrollProxy: scrollProxy)
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
                        modelContext.deleteStorageEvents(plannerOnlyEvents)
                    }

                    refreshCalendar()

                    DispatchQueue.main.asyncAfter(
                        deadline: .now() + .milliseconds(750)
                    ) {
                        plannerManager.toggleSelectMode()
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
                    id: IDConstants.TRANSFER_BUTTON,
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
            startOfDay: plannerStartOfDay,
            allDayEvents: allDayEvents,
            iconMap: settings.iconMap,
            namespace: namespace,
            settings: settings,
            location: plannerLocation,
            storageEvents: storageEvents,
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
    private func leftAdornment(event: PlannerEvent) -> some View {
        if let calendarEvent = event.calendarEvent,
            let calendar = calendarEvent.calendar
        {
            Image(
                systemName:
                    settings.iconMap[
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
    private func rightAdornment(event: PlannerEvent) -> some View {
        event.timeValueView(
            in: plannerStartOfDay.region,
            accentColor: accentColor
        ) {
            openPlannerEventSheet(event)
        }
    }

    @ViewBuilder
    private func bottomAdornment(event: PlannerEvent) -> some View {
        event.locationValueView(
            in: planner,
            settings: settings,
            deviceLocation: deviceLocationManager.location,
            accentColor: accentColor
        ) {
            openPlannerEventSheet(event)
        }
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
                            && !settings.isPlannerEventChecked(
                                event
                            )
                    },
                    actions: [
                        ConfirmationAction(
                            title: "Hide",
                            role: nil
                        ) { event in
                            _ = settings.toggleEvent(event)
                        },

                        ConfirmationAction(
                            title: "Delete",
                            role: .destructive
                        ) { event in
                            guard let calEvent = event.calendarEvent else {
                                return
                            }

                            calendarStore.delete(event: calEvent)
                            refreshCalendar()
                        },
                    ]
                )
            )
        }
    }

    // MARK: - Data Handlers

    private func refreshCalendar() {
        calendarStore.loadFreshCache(
            hiddenCalendarIds: settings.hiddenCalendarIds
        )
    }

    // MARK: - List Actions

    private func createEvent(
        near baseId: UUID?,
        offset: Int = 0
    ) {
        if let newId = modelContext.createStorageEvent(
            in: sortedOpenPlans,
            near: baseId,
            offset: offset,
            startOfDay: plannerStartOfDay,
            settings: settings
        ) {
            plannerManager.pendingFocusId = newId
        }
    }

    private func moveUncheckedEvent(from: Int, to: Int) {
        modelContext.movePlannerEvent(
            from: from,
            to: to,
            startOfDay: plannerStartOfDay,
            events: sortedOpenPlans,
            settings: settings
        )
    }

    private func handleEventTitleChange(event: PlannerEvent) {
        modelContext.handlePlannerEventTitleChange(
            event,
            startOfDay: plannerStartOfDay,
            eventKitStore: calendarStore.ekEventStore,
            defaultLocation: plannerLocation
        )
    }

    private func createLowerEvent(scrollProxy: ScrollViewProxy) {

        createEvent(
            near: sortedOpenPlans.last?.stableId,
            offset: 1
        )

        DispatchQueue.main.async {
            withAnimation {
                scrollProxy.scrollTo(
                    IDConstants.UNCHECKED_ITEMS,
                    anchor: .bottom
                )
            }
        }

    }

    // MARK: - Helpers

    private func deleteAllCheckedEvents() {
        modelContext.deleteStorageEvents(rawCheckedEvents)
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
        
        plannerManager.protectedId = event.stableId
        plannerManager.focusedId = nil

        eventSheetContext =
            EventSheetContext(
                plannerEvent: event,
                calendarEvent: nil
            )
    }

    private func togglePlannerEvent(_ event: PlannerEvent) -> Bool {
        return modelContext.togglePlannerEvent(
            event,
            settings: settings
        )
    }

}
