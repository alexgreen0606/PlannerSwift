//
//  ExpandedPlanner.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import EventKit
import SwiftData
import SwiftDate
import SwiftUI

// Clean

struct ExpandedPlannerView<Header: View>: View {
    let planner: Planner
    let header: Header
    let plannerDay: DateInRegion
    let plannerLocation: Location?
    let sortedPlannerEvents: [PlannerEvent]
    let calendarDayData: CalendarDayData
    let settings: PlannerSettings

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var todaystampManager: TodaystampWatcher
    @EnvironmentObject private var deviceLocationManager: DeviceLocationManager
    
    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var plannerManager = ListManager<PlannerEvent>(
        isItemChecked: { event in
            event.isChecked
        }
    )
    @State private var eventSheetContext: EventSheetContext?
    @State private var showTransferSheet = false

    @Namespace private var namespace

    // MARK: - Computed Variables

    private var plannerType: PlannerType {
        planner.datestamp <= todaystampManager.todaystamp
            ? .pastOrPresent : .future
    }

    private var visibleEvents: [PlannerEvent] {
        if planner.showChecked {
            return sortedOpenPlannerEvents + sortedCheckedPlannerEvents
        }

        return sortedOpenPlannerEvents
    }

    private var isAllSelected: Bool {
        !visibleEvents.isEmpty
            && plannerManager.selectedItemIds.count == visibleEvents.count
    }

    // MARK: Event Lists

    private var sortedOpenPlannerEvents: [PlannerEvent] {
        sortedPlannerEvents.filter(plannerManager.isItemInUncheckedList)
    }

    private var sortedCheckedPlannerEvents: [PlannerEvent] {
        sortedPlannerEvents.filter(plannerManager.isItemInCheckedList)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollViewReader { scrollProxy in
                PlannerListView(
                    eventSheetContext: $eventSheetContext,
                    plannerType: plannerType,
                    planner: planner,
                    plannerDay: plannerDay,
                    plannerLocation: plannerLocation,
                    sortedOpenPlannerEvents: sortedOpenPlannerEvents,
                    sortedCheckedPlannerEvents: sortedCheckedPlannerEvents,
                    sortedPlannerEvents: sortedPlannerEvents,
                    calendarDayData: calendarDayData,
                    showChecked: planner.showChecked,
                    namespace: namespace,
                    scrollProxy: scrollProxy,
                    settings: settings,
                    createEvent: createEvent
                )
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    upperLeftToolbar
                    upperRightToolbar
                    headerToolbar
                    lowerToolbar(scrollProxy: scrollProxy)
                }
                .animateSynchronousAction(from: plannerManager.isSelectMode)
            }
        }
        .overlay {
            NotificationsView()
        }

        // Event Sheet
        .sheet(item: $eventSheetContext) { context in
            EventFormView(
                sourcePlanner: planner,
                plannerEvent: context.plannerEvent,
                calendarEvent: context.calendarEvent,
                settings: settings,
            )
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
                startOfDay: plannerDay,
                settings: settings
            )
            .navigationTransition(
                .zoom(
                    sourceID: IdConstants.TRANSFER_BUTTON,
                    in: namespace
                )
            )
        }

        // Inject the environment objects last so they can be accessed in the sheets.
        .environmentObject(plannerManager)
        .environmentObject(notificationManager)
    }

    // MARK: - Toolbars

    // MARK: Upper Left Toolbar

    @ToolbarContentBuilder
    private var upperLeftToolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            if !plannerManager.isSelectMode {
                backButton
            } else {
                cancelSelectModeButton
            }
        }
    }

    private var backButton: some View {
        Button("Back", systemImage: "chevron.left") {
            dismiss()
        }
    }

    private var cancelSelectModeButton: some View {
        Button(
            "Cancel Select Mode",
            systemImage: "xmark",
            action: plannerManager.toggleSelectMode
        )
        // Note: This fixes a bug where opening select mode while a keyboard is open causes this button to
        // appear tinted as the accent color.
        .tint(Color.label)
    }

    // MARK: Header

    @ToolbarContentBuilder
    private var headerToolbar: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            header
        }
    }

    // MARK: Upper Right Toolbar

    @ToolbarContentBuilder
    private var upperRightToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if !plannerManager.isSelectMode {
                PlannerActionMenuView(
                    plannerType: plannerType,
                    planner: planner,
                    showChecked: planner.showChecked,
                    plannerEvents: sortedPlannerEvents,
                    visibleEvents: visibleEvents
                )
            } else {
                selectAllToggle
            }
        }
    }

    private var selectAllToggle: some View {
        Button {
            plannerManager.toggleSelectAll(visibleItems: visibleEvents)
        } label: {
            Text(isAllSelected ? "Deselect All" : "Select All")
                .fontWeight(.semibold)
        }
        .disabled(visibleEvents.isEmpty)
    }

    // MARK: Lower Toolbar

    @ToolbarContentBuilder
    private func lowerToolbar(scrollProxy: ScrollViewProxy)
        -> some ToolbarContent
    {
        ToolbarItemGroup(placement: .bottomBar) {
            if !plannerManager.isSelectMode {
                Spacer()
                createLowerEventButton(scrollProxy: scrollProxy)
            } else {
                SelectedEventActionsView(
                    showTransferSheet: $showTransferSheet,
                    settings: settings,
                    namespace: namespace
                )
            }
        }
    }

    private func createLowerEventButton(scrollProxy: ScrollViewProxy)
        -> some View
    {
        Button("Add", systemImage: "plus") {
            createLowerEvent(scrollProxy: scrollProxy)
        }
        .tint(accentColor.color)
    }

    // MARK: - Functions

    private func createEvent(at index: Int) {
        plannerManager.pendingFocusId = modelContext.createStorageEvent(
            at: index,
            in: sortedOpenPlannerEvents,
            startOfDay: plannerDay
        )
    }

    private func createLowerEvent(scrollProxy: ScrollViewProxy) {
        createEvent(at: sortedOpenPlannerEvents.count)
        scrollToBottom(scrollProxy: scrollProxy)
    }

    private func scrollToBottom(scrollProxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            withAnimation {
                scrollProxy.scrollTo(
                    IdConstants.UNCHECKED_ITEMS,
                    anchor: .bottom
                )
            }
        }
    }

}
