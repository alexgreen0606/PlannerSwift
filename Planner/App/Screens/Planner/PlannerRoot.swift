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
    let calendarDayData: CalendarDayData?
    let settings: PlannerSettings

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var todayService: TodayService
    @EnvironmentObject private var plannerCoverStore: PlannerCoverStore

    @StateObject private var plannerEngine = ListEngine<PlannerEvent>()

    @State private var eventSheetContext: EventSheetContext?
    @State private var showTransferSheet = false
    @State private var showLocationSheet = false

    @Namespace private var namespace

    private var plannerDay: DateInRegion {
        planner.datestamp.startOfDay(in: planner.region(settings: settings))
    }

    private var sortedPendingPlannerEvents: [PlannerEvent] {
        sortedPlannerEvents.filter { event in
            (!event.isCompleted
                && !plannerEngine.newlyPendingIds.contains(event.stableId))
                || plannerEngine.newlyCompletedIds.contains(event.stableId)
        }
    }

    private var sortedCompletePlannerEvents: [PlannerEvent] {
        sortedPlannerEvents.filter { event in
            (event.isCompleted
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

    // TODO: this will be moved into the header view
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
                        plannerDay: plannerDay,
                        sortedPlannerEvents: sortedPlannerEvents,
                        sortedPendingPlannerEvents:
                        sortedPendingPlannerEvents,
                        sortedCompletePlannerEvents:
                        sortedCompletePlannerEvents,
                        calendarDayData: calendarDayData,
                        showCompleted: planner.showCompleted,
                        scrollProxy: scrollProxy,
                        settings: settings,
                        namespace: namespace,
                        createEvent: createEvent
                    )
                    .toolbar {
                        topLeadingToolbar
                        headerToolbar
                        topTrailingToolbar
                        bottomToolbar(scrollProxy: scrollProxy)
                    }
                    .navigationBarTitleDisplayMode(.inline)
                }
            }

            // MARK: Transfer Events Form

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
            .environmentObject(plannerEngine)

            // MARK: Event Form

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
        }
    }

    // MARK: - Toolbars

    @ToolbarContentBuilder
    private var topLeadingToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if !plannerEngine.isSelectMode {
                BackButtonView {
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
                }
            } else {
                CancelButtonView(cancel: plannerEngine.toggleSelectMode)
            }
        }
    }

    @ToolbarContentBuilder
    private var headerToolbar: some ToolbarContent {
        if !plannerEngine.isSelectMode {
            ToolbarItem(placement: .topBarLeading) {
                // TODO: change default header to follow planner behavior: date for next 7 days, else weekday
                PlannerHeaderView(
                    datestamp: planner.datestamp,
                    customTextScale: 1.1,
                    iconFormat: showHeaderDateIcon
                        ? .conciseMonth : .conciseWeekday,
                    iconSize: 32,
                    iconDetailSize: showHeaderDateIcon ? 9 : 11,
                    iconDetailOffset: showHeaderDateIcon ? 3 : 18
                )
                .frame(width: 250, alignment: .leading)
                .padding(.leading, -8)
            }
            .sharedBackgroundVisibility(.hidden)
        }
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

    @ToolbarContentBuilder
    private func bottomToolbar(scrollProxy: ScrollViewProxy)
        -> some ToolbarContent
    {
        if !plannerEngine.isSelectMode {
            ToolbarSpacer(placement: .bottomBar)
            ToolbarItem(placement: .bottomBar) {
                CreateLowerItemButtonView {
                    createLowerEvent(scrollProxy: scrollProxy)
                }
            }
        } else {
            SelectedEventActionsView(
                showTransferSheet: $showTransferSheet,
                planner: planner,
                namespace: namespace
            )
        }
    }

    // MARK: - Functions

    private func createEvent(at index: Int) {
        plannerEngine.pendingFocusId = modelContext.createPlannerEvent(
            at: index,
            in: sortedPlannerEvents,
            startOfDay: plannerDay
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
}
