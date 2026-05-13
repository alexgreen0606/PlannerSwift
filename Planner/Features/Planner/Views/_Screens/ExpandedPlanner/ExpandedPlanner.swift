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

struct ExpandedPlannerView<Header: View>: View {
    let planner: Planner
    let header: Header
    let plannerDay: DateInRegion
    let plannerLocation: Location?
    let sortedPlannerEvents: [PlannerEvent]
    let calendarDayData: CalendarDayData?
    let settings: PlannerSettings

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var todaystampManager: TodaystampService
    @EnvironmentObject private var PlannerCoverStore: PlannerCoverStore
    @EnvironmentObject private var LocationService: LocationService

    @StateObject private var plannerManager = ListStore<PlannerEvent>(
        isItemChecked: { event in
            event.isChecked
        }
    )
    @State private var eventSheetContext: EventSheetContext?
    @State private var showTransferSheet = false
    @State private var showLocationSheet = false

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
        ToastRootView(
            // TODO: focusing must blur the keyboard
            ListStore: plannerManager
        ) {
            NavigationStack {
                ScrollViewReader { scrollProxy in
                    ZStack {
                        PlannerListView(
                            showLocationSheet: $showLocationSheet,
                            eventSheetContext: $eventSheetContext,
                            plannerType: plannerType,
                            planner: planner,
                            plannerDay: plannerDay,
                            plannerLocation: plannerLocation,
                            sortedOpenPlannerEvents:
                                sortedOpenPlannerEvents,
                            sortedCheckedPlannerEvents:
                                sortedCheckedPlannerEvents,
                            sortedPlannerEvents: sortedPlannerEvents,
                            calendarDayData: calendarDayData,
                            showChecked: planner.showChecked,
                            namespace: namespace,
                            scrollProxy: scrollProxy,
                            settings: settings,
                            createEvent: createEvent
                        )
                        .transition(.opacity)
                    }
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

            // MARK: Event Sheet
            .sheet(item: $eventSheetContext) { context in
                EventFormView(
                    sourcePlanner: planner,
                    plannerEvent: context.plannerEvent,
                    calendarEvent: context.calendarEvent,
                    settings: settings
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

            // MARK: Transfer Event Sheet
            .sheet(isPresented: $showTransferSheet) {
                TransferEventsFormView(
                    sourceStartOfDay: plannerDay,
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
    }

    // MARK: - Toolbars

    // MARK: Upper Left Toolbar

    @ToolbarContentBuilder
    private var upperLeftToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if !plannerManager.isSelectMode {
                backButton
            } else {
                cancelSelectModeButton
            }
        }
    }

    private var backButton: some View {
        Button("Back", systemImage: "chevron.left") {
            if PlannerCoverStore.isPresentingDefault {
                if PlannerCoverStore.todaystampAtInit != planner.datestamp {
                    PlannerCoverStore.isPresentingDefault = false
                } else {
                    withAnimation(.linear) {
                        PlannerCoverStore.isPresentingDefault = false
                    }
                }
            }
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
        if !plannerManager.isSelectMode {
            ToolbarItem(placement: .topBarLeading) {
                header
                    .frame(width: 250, alignment: .leading)
            }
            .sharedBackgroundVisibility(.hidden)
        }
    }

    // MARK: Upper Right Toolbar

    @ToolbarContentBuilder
    private var upperRightToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if !plannerManager.isSelectMode {
                PlannerActionMenuView(
                    showLocationSheet: $showLocationSheet,
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
        if !plannerManager.isSelectMode {
            ToolbarSpacer(placement: .bottomBar)
            ToolbarItem(placement: .bottomBar) {
                createLowerEventButton(scrollProxy: scrollProxy)
            }
        } else {
            SelectedPlannerEventActionsView(
                showTransferSheet: $showTransferSheet,
                planner: planner,
                namespace: namespace
            )
        }
    }

    private func createLowerEventButton(scrollProxy: ScrollViewProxy)
        -> some View
    {
        Button("Add", systemImage: "plus") {
            createLowerEvent(scrollProxy: scrollProxy)
        }
        .buttonStyle(.glassProminent)
        .tint(accentColor.color)
    }

    // MARK: - Functions

    private func createEvent(at index: Int) {
        plannerManager.pendingFocusId = modelContext.createPlannerEvent(
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
