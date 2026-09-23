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
    private let planner: Planner
    private let sortedPlannerEvents: [PlannerEvent]
    private let sortedEventChips: [PlannerEvent]
    private let sortedBirthdayChips: [PlannerEvent]
    private let settings: Settings

    init(
        planner: Planner,
        sortedPlannerEvents: [PlannerEvent],
        sortedEventChips: [PlannerEvent],
        sortedBirthdayChips: [PlannerEvent],
        settings: Settings
    ) {
        self.planner = planner
        self.sortedPlannerEvents = sortedPlannerEvents
        self.sortedEventChips = sortedEventChips
        self.sortedBirthdayChips = sortedBirthdayChips
        self.settings = settings

        self._plannerEngine = StateObject(
            wrappedValue: ListEngine<PlannerEvent>(
                toggleState: ListItemToggleState(
                    isToggled: { $0.isCompleted },
                    setIsToggled: { event, isCompleted in
                        // Note: In the future isCompleted should be replaced with completedOn only.
                        if isCompleted {
                            event.completedOn = planner.datestamp
                            event.isCompleted = true
                        } else {
                            event.completedOn = ""
                            event.isCompleted = false
                        }
                    }
                ),
                settings: settings
            )
        )
    }

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var todayService: TodayService
    @EnvironmentObject private var calendarService: CalendarService
    @EnvironmentObject private var plannerCoverStore: PlannerCoverStore

    @StateObject private var plannerEngine: ListEngine<PlannerEvent>

    @State private var eventSheetContext: PlannerEventSheetContext?
    @State private var showTransferSheet = false
    @State private var showLocationSheet = false

    @State private var isFlaggedById: [UUID: Bool] = [:]

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
            return sortedPlannerEvents + sortedEventChips
        }

        return sortedPendingPlannerEvents + sortedEventChips
    }

    private var plannerLocation: Location? {
        planner.location(
            settings: settings
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
                        handleEventChange: handleEventChange,
                        handleEventClick: handleEventClick
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

            // MARK: Refresh the engine callback so that saved items have up-to-date flagged state.

            .task(id: isFlaggedById) {
                plannerEngine.setKeyboardState(
                    ListItemKeyboardState<PlannerEvent>(
                        onFocus: { event in
                            isFlaggedById[event.stableId] = event.isFlagged
                        },
                        onBlur: { event in
                            event.isFlagged = isEventFlagged(event)
                        }
                    )
                )
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
                    if context.plannerEvent.eKEventContext?
                        .calendarAllowsContentModifications == false
                    {
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
        let flagImage =
            isEventFlagged(plannerEngine.focusedItem) ? "flag.fill" : "flag"

        return ListActionToolbarView<
            PlannerEvent,
            SelectedEventActionsView
        >(
            keyboardAccessory: ListKeyboardAccessoryView(
                iconImageNames: ["info", flagImage],
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

    private func handleToolbarTap(icon: String) {
        if let event = plannerEngine.focusedItem {
            switch icon {
            case "info":
                handleEventClick(event)
            case "flag", "flag.fill":
                isFlaggedById[event.stableId] = !isEventFlagged(event)
            default:
                break
            }
        }
    }

    private func handleEventChange(event: PlannerEvent) {
        modelContext.handlePlannerEventChange(
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

    private func handleEventClick(_ event: PlannerEvent) {
        let openModal = plannerEngine.handleItemClick(event)
        if openModal {
            DispatchQueue.main.async {
                eventSheetContext =
                    PlannerEventSheetContext(
                        plannerEvent: event
                    )
            }
        }
    }

    private func isEventFlagged(_ event: PlannerEvent?) -> Bool {
        guard let event else { return false }

        return isFlaggedById[event.stableId] ?? event.isFlagged
    }
}
