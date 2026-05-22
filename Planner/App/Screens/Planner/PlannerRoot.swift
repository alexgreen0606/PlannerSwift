//
//  PlannerRoot.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import EventKit
import SwiftData
import SwiftDate
import SwiftUI

// TODO: pass in needed stuff, not context.
struct PlannerRootView: View {
    let planner: Planner
    let plannerDay: DateInRegion
    let plannerLocation: Location?
    let eventContext: PlannerEventContext
    let settings: PlannerSettings

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var plannerEngine: ListEngine<PlannerEvent>
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var todaystampService: TodaystampService
    @EnvironmentObject private var PlannerCoverStore: PlannerCoverStore
    @EnvironmentObject private var LocationService: LocationService

    @State private var eventSheetContext: EventSheetContext?
    @State private var showTransferSheet = false
    @State private var showLocationSheet = false

    @Namespace private var namespace

    // MARK: - Computed Variables
    
    private var sortedPendingPlannerEvents: [PlannerEvent] {
        eventContext.sortedPlannerEvents.filter { event in
            (!event.isCompleted
                && !plannerEngine.newlyUncheckedIds.contains(event.stableId))
                || plannerEngine.newlyCheckedIds.contains(event.stableId)
        }
    }

    private var sortedCompletePlannerEvents: [PlannerEvent] {
        eventContext.sortedPlannerEvents.filter { event in
            (event.isCompleted
                && !plannerEngine.newlyCheckedIds.contains(event.stableId))
                || plannerEngine.newlyUncheckedIds.contains(event.stableId)
        }
    }

    private var visibleEvents: [PlannerEvent] {
        if planner.showChecked {
            return eventContext.sortedPlannerEvents
        }

        return sortedPendingPlannerEvents
    }

    private var isAllSelected: Bool {
        !visibleEvents.isEmpty
            && plannerEngine.selectedItemIds.count == visibleEvents.count
    }


    // MARK: - Body

    var body: some View {
        ToastRootView(
            listEngine: plannerEngine
        ) {
            NavigationStack {
                ScrollViewReader { scrollProxy in
                    ZStack {
                        PlannerListView(
                            showLocationSheet: $showLocationSheet,
                            eventSheetContext: $eventSheetContext,
                            planner: planner,
                            plannerDay: plannerDay,
                            plannerLocation: plannerLocation,
                            sortedPlannerEvents: eventContext.sortedPlannerEvents,
                            sortedPendingPlannerEvents:
                                sortedPendingPlannerEvents,
                            sortedCompletePlannerEvents:
                                sortedCompletePlannerEvents,
                            calendarDayData: eventContext.calendarDayData,
                            showCompleted: planner.showChecked,
                            scrollProxy: scrollProxy,
                            settings: settings,
                            namespace: namespace,
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
                    .animateSynchronousAction(from: plannerEngine.isSelectMode)
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
                    plannerEngine.protectedId = nil
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
                        sourceID: ListIds.TRANSFER_BUTTON,
                        in: namespace
                    )
                )
            }
        }
    }

    // MARK: - Toolbars

    // MARK: Upper Left Toolbar

    @ToolbarContentBuilder
    private var upperLeftToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if !plannerEngine.isSelectMode {
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
            action: plannerEngine.toggleSelectMode
        )
        // Note: This fixes a bug where opening select mode while a keyboard is open causes this button to
        // appear tinted as the accent color.
        .tint(Color.label)
    }

    // MARK: Header

    @ToolbarContentBuilder
    private var headerToolbar: some ToolbarContent {
        if !plannerEngine.isSelectMode {
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
            if !plannerEngine.isSelectMode {
                PlannerActionMenuView(
                    showLocationSheet: $showLocationSheet,
                    planner: planner,
                    plannerEvents: eventContext.sortedPlannerEvents,
                    hasVisibleEvents: !visibleEvents.isEmpty
                )
            } else {
                selectAllToggle
            }
        }
    }

    private var selectAllToggle: some View {
        Button {
            plannerEngine.toggleSelectAll(visibleItems: visibleEvents)
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
        if !plannerEngine.isSelectMode {
            ToolbarSpacer(placement: .bottomBar)
            ToolbarItem(placement: .bottomBar) {
                createLowerEventButton(scrollProxy: scrollProxy)
            }
        } else {
            SelectedEventActionsView(
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

    // MARK: - View Builders

    @ViewBuilder
    private var header: some View {
        let showDateIcon =
            planner.datestamp.isNext7Days(
                todaystamp: todaystampService.todaystamp
            )
            || planner.datestamp.isWithinADay(
                todaystamp: todaystampService.todaystamp
            )

        PlannerHeaderView(
            datestamp: planner.datestamp,
            customTextScale: 1.1,
            iconSize: 32,
            iconDetailSize: showDateIcon ? 9 : 11,
            iconDetailOffset: showDateIcon ? 3 : 18
        )
    }

    // MARK: - Functions

    private func createEvent(at index: Int) {
        plannerEngine.pendingFocusId = modelContext.createPlannerEvent(
            at: index,
            in: sortedPendingPlannerEvents,
            startOfDay: plannerDay
        )
    }

    private func createLowerEvent(scrollProxy: ScrollViewProxy) {
        createEvent(at: sortedPendingPlannerEvents.count)
        scrollToBottom(scrollProxy: scrollProxy)
    }

    private func scrollToBottom(scrollProxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            withAnimation {
                scrollProxy.scrollTo(
                    ListIds.UNCHECKED_ITEMS,
                    anchor: .bottom
                )
            }
        }
    }
}
