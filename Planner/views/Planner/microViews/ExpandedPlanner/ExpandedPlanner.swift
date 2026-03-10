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
    let planner: Planner
    let plannerStartOfDay: DateInRegion
    let plannerLocation: Location?
    let sortedPlannerEvents: [PlannerEvent]
    let allDayEvents: [EKEvent]
    let settings: PlannerSettings

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var todaystampManager: TodaystampWatcher
    @EnvironmentObject private var deviceLocationManager: DeviceLocationManager

    @StateObject private var plannerManager = ListManager<PlannerEvent>()

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

    private var rawCheckedEvents: [PlannerEvent] {
        sortedPlannerEvents.filter { $0.isChecked }
    }

    // MARK: - Select Mode

    private var visibleEvents: [PlannerEvent] {
        if showChecked {
            return sortedOpenPlannerEvents + sortedCheckedPlans
        }

        return sortedOpenPlannerEvents
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

    private var sortedOpenPlannerEvents: [PlannerEvent] {
        sortedPlannerEvents
            .filter {
                (!$0.isChecked
                    && !plannerManager.newlyUncheckedIds.contains($0.stableId))
                    || plannerManager.newlyCheckedIds.contains($0.stableId)
            }
    }

    private var sortedCheckedPlans: [PlannerEvent] {
        sortedPlannerEvents
            .filter {
                ($0.isChecked
                    && !plannerManager.newlyCheckedIds.contains($0.stableId))
                    || plannerManager.newlyUncheckedIds.contains($0.stableId)
            }
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { scrollProxy in
                SortableListView(
                    uncheckedItems: sortedOpenPlannerEvents,
                    checkedItems: sortedCheckedPlans,
                    showChecked: showChecked,
                    checkedHeader: plannerType.checkedHeader,
                    emptyUncheckedLabel: "No plans",
                    emptyCheckedLabel: plannerType.emptyCheckedLabel,
                    tint: eventTint,
                    scrollProxy: scrollProxy,
                    createItem: createEvent,
                    moveItem: moveUncheckedEvent,
                    floatingInfo: chipSpread,
                    customToggleConfig: toggleEventIconConfig,
                    namespace: namespace,
                    toolbarIcons: ["clock"],
                    tapToolbar: handleToolbarTap,
                    leftAdornment: leftAdornment,
                    rightAdornment: rightAdornment,
                    bottomAdornment: bottomAdornment,
                    handleTitleChange: handleEventTitleChange,
                    checkedFooter: plannerType.getCheckedFooter(
                        for: plannerStartOfDay
                    ),
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
            )
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
                    sourceID: IdConstants.TRANSFER_BUTTON,
                    in: namespace
                )
            )
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
                .tint(accentColor.color)
            } else {
                DeleteSelectedButtonView(
                    itemsLabel: "events",
                    disabled: plannerManager.selectedItemIds.isEmpty,
                    message:
                        "Calendar and planner events will be lost."
                ) {
                    let selectedEvents = plannerManager.selectedItems

                    var plannerOnlyEvents: [PlannerEvent] = []

                    for event in selectedEvents {
                        if let calEvent = event.calendarEvent {
                            // Delete from device calendar.
                            calendarStore.ekEventStore.deleteEvent(calEvent)
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
                    id: IdConstants.TRANSFER_BUTTON,
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
            sortedPlannerEvents: sortedPlannerEvents,
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
                    calendar.systemImageName(settings: settings)
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
            deviceLocation: deviceLocationManager.deviceLocation,
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
                        && !event.isChecked
                    },
                    actions: [
                        ConfirmationAction(
                            title: "Hide",
                            role: nil
                        ) { event in
                            event.isChecked = true
                            
                            // TODO: save context
                        },

                        ConfirmationAction(
                            title: "Delete",
                            role: .destructive
                        ) { event in
                            guard let calEvent = event.calendarEvent else {
                                return
                            }

                            calendarStore.ekEventStore.deleteEvent(calEvent)
                            refreshCalendar()
                        },
                    ]
                )
            )
        }
    }

    // MARK: - Data Handlers

    private func refreshCalendar() {
        calendarStore.attemptFreshLoad(
            hiddenCalendarIds: settings.hiddenCalendarIds
        )
    }

    // MARK: - List Actions

    private func createEvent(
        near baseId: UUID?,
        offset: Int = 0
    ) {
        if let newId = modelContext.createStorageEvent(
            in: sortedOpenPlannerEvents,
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
            plannerStartOfDay: plannerStartOfDay,
            sortedEvents: sortedOpenPlannerEvents
        )
    }

    private func handleEventTitleChange(event: PlannerEvent) {
        modelContext.handlePlannerEventTitleChange(
            event,
            plannerStartOfDay: plannerStartOfDay,
            eventKitStore: calendarStore.ekEventStore,
            defaultLocation: plannerLocation
        )
    }

    private func createLowerEvent(scrollProxy: ScrollViewProxy) {

        createEvent(
            near: sortedOpenPlannerEvents.last?.stableId,
            offset: 1
        )

        DispatchQueue.main.async {
            withAnimation {
                scrollProxy.scrollTo(
                    IdConstants.UNCHECKED_ITEMS,
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

}
