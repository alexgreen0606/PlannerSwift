//
//  RoutineRoot.swift
//  Planner
//
//  Created by Alex Green on 4/5/26.
//

import SwiftData
import SwiftUI

struct RoutineRootView: View {
    @Binding var routineCoverContext: Weekday?
    let weekday: Weekday
    let sortedRoutineEvents: [RoutineEvent]

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var calendarStore: CalendarService
    @EnvironmentObject private var plannerSyncService: PlannerSyncService

    @StateObject private var routineEngine = ListEngine<RoutineEvent>()

    @State private var showTransferSheet = false
    @State private var routineEventSheetContext: RoutineEventSheetContext? = nil

    @State private var invalidatedEventIds: Set<UUID> = []

    @Namespace private var namespace

    // MARK: - Body

    var body: some View {
        ToastRootView(listEngine: routineEngine) {
            NavigationStack {
                ScrollViewReader { scrollProxy in
                    SortableTextfieldListView(
                        sortedItems: sortedRoutineEvents,
                        toolbarSystemImageNames: ["info"],
                        onToolbarTap: handleToolbarTap,
                        createItem: createEvent,
                        moveItem: moveEvent,
                        deleteItem: deleteEvent,
                        handleTitleChange: handleEventTitleChange,
                        emptyPendingLabel: "No \(weekday.label) routine",
                        tint: { _ in accentColor.color },
                        toggleConfig: eventToggleConfig,
                        leftAdornment: { _ in EmptyView() },
                        rightAdornment: timeAdornment,
                        bottomAdornment: weekdaysAdornment,
                        scrollProxy: scrollProxy,
                        namespace: namespace
                    )
                    .toolbar {
                        topLeadingToolbar
                        topTrailingToolbar
                        bottomToolbar(scrollProxy: scrollProxy)
                    }
                    .navigationTitle("\(weekday.label) Routine")
                    .navigationSubtitle("Recurring Events")
                    .navigationBarTitleDisplayMode(.inline)
                }
            }

            // MARK: Transfer Routine Events Form

            .sheet(isPresented: $showTransferSheet) {
                TransferRoutineEventsFormView(
                    sourceDayOfWeek: weekday,
                    sortedSourceRoutineEvents: sortedRoutineEvents,
                    openRoutine: openRoutine
                )
                .navigationTransition(
                    .zoom(
                        sourceID: ListIds.TRANSFER_BUTTON,
                        in: namespace
                    )
                )
            }
            .environmentObject(routineEngine)

            // MARK: Routine Event Form

            .sheet(item: $routineEventSheetContext) { context in
                RoutineEventFormView(
                    sourceRoutineEvent: context.routineEvent,
                    sourceDayOfWeek: weekday,
                    sortedSourceEvents: sortedRoutineEvents,
                    openRoutine: openRoutine
                )
                .navigationTransition(
                    .zoom(
                        sourceID: context.id,
                        in: namespace
                    )
                )
                .onDisappear {
                    routineEngine.protectedId = nil
                }
            }
        }
    }

    // MARK: - Toolbars

    @ToolbarContentBuilder
    private var topLeadingToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if !routineEngine.isSelectMode {
                BackButtonView()
            } else {
                CancelButtonView(cancel: routineEngine.toggleSelectMode)
            }
        }
    }

    @ToolbarContentBuilder
    private var topTrailingToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if !routineEngine.isSelectMode {
                RoutineActionMenuView(
                    weekday: weekday,
                    routineEvents: sortedRoutineEvents
                )
            } else {
                SelectAllToggleView(visibleItems: sortedRoutineEvents)
            }
        }
    }

    @ToolbarContentBuilder
    private func bottomToolbar(scrollProxy: ScrollViewProxy)
        -> some ToolbarContent
    {
        if !routineEngine.isSelectMode {
            ToolbarSpacer(placement: .bottomBar)
            ToolbarItem(placement: .bottomBar) {
                CreateLowerItemButtonView {
                    createLowerEvent(scrollProxy: scrollProxy)
                }
            }
        } else {
            SelectedRoutineEventActionsView(
                showTransferSheet: $showTransferSheet,
                weekday: weekday,
                namespace: namespace
            )
        }
    }

    // MARK: - View Builders

    private func timeAdornment(event: RoutineEvent) -> some View {
        event.timeAdornment(
            accentColor: accentColor
        ) {
            openRoutineEventSheet(for: event)
        }
    }

    private func weekdaysAdornment(event: RoutineEvent) -> some View {
        event.weekdaysAdornment {
            openRoutineEventSheet(for: event)
        }
    }

    // MARK: - Functions

    private func handleToolbarTap(icon _: String, event: RoutineEvent) {
        openRoutineEventSheet(for: event)
    }

    private func createEvent(at index: Int) {
        routineEngine.pendingFocusId = modelContext.createRoutineEvent(
            at: index,
            in: sortedRoutineEvents,
            weekday: weekday
        )
    }

    private func moveEvent(from: Int, to: Int) {
        modelContext.moveRoutineEvent(
            from: from,
            to: to,
            on: weekday,
            sortedRoutineEvents: sortedRoutineEvents
        )
        plannerSyncService.invalidateRoutines(weekdays: [weekday])
    }

    private func deleteEvent(_ event: RoutineEvent) {
        modelContext.deleteRoutineEvent(
            event,
            ekEventStore: calendarStore.ekEventStore,
            PlannerSyncStore: plannerSyncService
        )
    }

    private func handleEventTitleChange(event: RoutineEvent) {
        modelContext.handleRoutineEventTitleChange(event)
        if !invalidatedEventIds.contains(event.stableId) {
            // Mark this event's weekdays for refresh in the planner.
            plannerSyncService.invalidateRoutines(
                weekdays: event.weekdays
            )
            invalidatedEventIds.insert(event.stableId)
        }
    }

    private func eventToggleConfig(_ event: RoutineEvent) -> ToggleConfig? {
        ToggleConfig(
            pendingIconConfig: IconConfig(
                name: "minus.circle",
                primaryColor: Color.red,
                secondaryColor: Color.tertiary
            ),
            completedIconConfig: IconConfig(name: ""),
            confirmation: removeRoutineEventFromWeekdayConfig(
                event: event,
                weekday: weekday,
                remove: {
                    removeEventFromWeekday(event)
                },
                delete: {
                    deleteEventEverywhere(event)
                }
            ),
            onClick: {
                if routineEngine.focusedId == event.stableId {
                    routineEngine.focusedId = nil
                }
            }
        )
    }

    private func createLowerEvent(scrollProxy: ScrollViewProxy) {
        createEvent(at: sortedRoutineEvents.count)
        scrollProxy.scrollToBottomOfList()
    }

    private func openRoutine(for weekday: Weekday) {
        routineCoverContext = weekday
    }

    private func openRoutineEventSheet(for event: RoutineEvent) {
        if routineEngine.isSelectMode {
            routineEngine.toggleItem(event)
            return
        }
        
        handleEventTitleChange(event: event)

        routineEngine.protectedId = event.stableId
        routineEngine.focusedId = nil
        
        DispatchQueue.main.async {
            routineEventSheetContext = RoutineEventSheetContext(
                routineEvent: event
            )
        }
    }

    private func removeEventFromWeekday(_ event: RoutineEvent) {
        modelContext.deleteRoutineEvents(
            [event],
            from: weekday,
            ekEventStore: calendarStore.ekEventStore,
            PlannerSyncStore: plannerSyncService
        )
    }

    private func deleteEventEverywhere(_ event: RoutineEvent) {
        modelContext.deleteRoutineEvent(
            event,
            ekEventStore: calendarStore.ekEventStore,
            PlannerSyncStore: plannerSyncService
        )
    }
}
