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

struct PlannerRootView: View {
    let planner: Planner
    let sortedPlannerEvents: [PlannerEvent]
    let sortedEventChips: [PlannerEvent]
    let sortedBirthdayChips: [PlannerEvent]
    let settings: Settings

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var todayService: TodayService
    @EnvironmentObject private var calendarService: CalendarService
    @EnvironmentObject private var locationService: LocationService
    @EnvironmentObject private var plannerCoverStore: PlannerCoverStore

    @StateObject private var plannerEngine = ListEngine<PlannerEvent>(
        toggleState: ListItemToggleState(
            isToggled: { $0.isCompleted },
            setIsToggled: { $0.isCompleted = $1 }
        )
    )

    @State private var eventSheetContext: PlannerEventSheetContext?
    @State private var showTransferSheet = false
    @State private var showLocationSheet = false

    @Namespace private var namespace

    private var startOfDay: DateInRegion {
        planner.startOfDay(settings: settings)
    }

    private var sortedPendingPlannerEvents: [PlannerEvent] {
        sortedPlannerEvents.filter { event in
            (!plannerEngine.isItemToggled(event)
                && !plannerEngine.newlyPendingIds.contains(event.stableId))
                || plannerEngine.newlyCompletedIds.contains(event.stableId)
        }
    }

    private var sortedCompletePlannerEvents: [PlannerEvent] {
        sortedPlannerEvents.filter { event in
            (plannerEngine.isItemToggled(event)
                && !plannerEngine.newlyCompletedIds.contains(event.stableId))
                || plannerEngine.newlyPendingIds.contains(event.stableId)
        }
    }

    private var visibleEvents: [PlannerEvent] {
        if planner.showCompleted {
            return sortedPlannerEvents
        }

        return sortedPendingPlannerEvents
    }

    private var plannerLocation: Location? {
        planner.location(
            settings: settings,
            deviceLocation: locationService.deviceLocation
        )
    }

    private var showHeaderDateIcon: Bool {
        planner.datestamp.isNext7Days(
            todaystamp: todayService.todaystamp
        )
    }

    // MARK: - Body

    var body: some View {
        ToastRootView(listEngine: plannerEngine) {
            NavigationStack {
                ScrollViewReader { scrollProxy in
                    PlannerContentsListView(
                        showLocationSheet: $showLocationSheet,
                        eventSheetContext: $eventSheetContext,
                        planner: planner,
                        startOfDay: startOfDay,
                        plannerLocation: plannerLocation,
                        sortedPlannerEvents: sortedPlannerEvents,
                        sortedPendingPlannerEvents:
                            sortedPendingPlannerEvents,
                        sortedCompletePlannerEvents:
                            sortedCompletePlannerEvents,
                        sortedEventChips: sortedEventChips,
                        sortedBirthdayChips: sortedBirthdayChips,
                        showCompleted: planner.showCompleted,
                        scrollProxy: scrollProxy,
                        settings: settings,
                        namespace: namespace,
                        createEvent: createEvent,
                        handleEventTitleChange: handleEventTitleChange,
                        openPlannerEventSheet: openPlannerEventSheet
                    )
                    .safeAreaBar(edge: .bottom) {
                        actionToolbar(scrollProxy: scrollProxy)
                    }
                    .toolbar {
                        topLeadingToolbar
                        headerToolbar
                        topTrailingToolbar
                    }
                    .navigationBarTitleDisplayMode(.inline)
                }
            }

            // MARK: Transfer Events Form

            .sheet(isPresented: $showTransferSheet) {
                TransferEventsFormView(
                    sourceStartOfDay: startOfDay,
                    settings: settings
                )
                .navigationTransition(
                    .zoom(
                        sourceID: ListIds.TRANSFER_BUTTON,
                        in: namespace
                    )
                )
            }
            .environmentObject(plannerEngine)

            // MARK: Event Form

            .sheet(item: $eventSheetContext) { context in
                Group {
                    if context.plannerEvent.eKEventContext?.calendarAllowsContentModifications == false {
                        ViewCalendarEventFormView(
                            plannerEvent: context.plannerEvent,
                            ekEventStore: calendarService.ekEventStore
                        )
                        .ignoresSafeArea()
                        .presentationDetents([.height(300)])
                    } else {
                        EventFormView(
                            plannerEvent: context.plannerEvent,
                            planner: planner,
                            ekEventStore: calendarService.ekEventStore,
                            settings: settings
                        )
                    }
                }
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
        }
    }

    // MARK: - Toolbars

    @ToolbarContentBuilder
    private var topLeadingToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if !plannerEngine.isSelectMode {
                BackButtonView(handleSideEffects: {
                    if plannerCoverStore.showTodayDefault {
                        if plannerCoverStore.todaystampAtInit
                            != planner.datestamp
                        {
                            plannerCoverStore.showTodayDefault = false
                        } else {
                            withAnimation(.linear) {
                                plannerCoverStore.showTodayDefault = false
                            }
                        }
                    }
                })
            } else {
                CancelButtonView(cancel: plannerEngine.toggleSelectMode)
            }
        }
    }

    @ToolbarContentBuilder
    private var headerToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            PlannerHeaderView(
                datestamp: planner.datestamp,
                iconSize: 32,
                iconDetailSize: showHeaderDateIcon ? 9 : 11,
                iconDetailOffset: showHeaderDateIcon ? 3 : 18
            )
            .frame(
                width: plannerEngine.isSelectMode ? 162 : 242,
                alignment: .leading
            )
        }
        .sharedBackgroundVisibility(.hidden)
    }

    @ToolbarContentBuilder
    private var topTrailingToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if !plannerEngine.isSelectMode {
                PlannerActionMenuView(
                    showLocationSheet: $showLocationSheet,
                    planner: planner,
                    plannerEvents: sortedPlannerEvents,
                    hasVisibleEvents: !visibleEvents.isEmpty
                )
            } else {
                SelectAllToggleView(visibleItems: visibleEvents)
            }
        }
    }

    // MARK: - View Builder

    private func actionToolbar(scrollProxy: ScrollViewProxy) -> some View {
        ListActionToolbarView<
            PlannerEvent,
            SelectedEventActionsView
        >(
            keyboardAccessory: ListKeyboardAccessoryView(
                items: sortedPendingPlannerEvents,
                iconImageNames: ["info"],
                onIconTap: handleToolbarTap
            ),
            selectedItemActions: SelectedEventActionsView(
                showTransferSheet: $showTransferSheet,
                planner: planner,
                namespace: namespace
            ),
            createItem: {
                createLowerEvent(scrollProxy: scrollProxy)
            }
        )
    }

    // MARK: - Functions

    private func createEvent(at index: Int) {
        plannerEngine.pendingFocusId = modelContext.createPlannerEvent(
            at: index,
            in: sortedPlannerEvents,
            startOfDay: startOfDay
        )
    }

    private func handleToolbarTap(icon _: String, event: PlannerEvent) {
        openPlannerEventSheet(event)
    }

    private func handleEventTitleChange(event: PlannerEvent) {
        return modelContext.handlePlannerEventTitleChange(
            event,
            in: planner,
            startOfDay: startOfDay,
            plannerLocation: plannerLocation,
            ekEventStore: calendarService.ekEventStore,
            settings: settings
        )
    }

    private func createLowerEvent(scrollProxy: ScrollViewProxy) {
        let targetIndex = getInsertionIndex(
            pendingIndex: sortedPendingPlannerEvents.count,
            sortedPendingItems: sortedPendingPlannerEvents,
            sortedItems: sortedPlannerEvents
        )

        createEvent(at: targetIndex)
        scrollProxy.scrollToBottomOfList()
    }

    private func openPlannerEventSheet(_ event: PlannerEvent) {
        if plannerEngine.isSelectMode || plannerEngine.isItemToggled(event) {
            plannerEngine.toggleItem(event)
            return
        }

        handleEventTitleChange(event: event)

        plannerEngine.protectedId = event.stableId
        plannerEngine.focusedId = nil

        DispatchQueue.main.async {
            eventSheetContext =
                PlannerEventSheetContext(
                    plannerEvent: event
                )
        }
    }
}
