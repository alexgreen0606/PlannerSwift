//
//  RoutineRoot.swift
//  Planner
//
//  Created by Alex Green on 4/5/26.
//

import SwiftData
import SwiftDate
import SwiftUI

struct RoutineRootView: View {
    @Binding var routineCoverContext: Weekday?
    let routine: Routine
    let sortedRoutineEventContexts: [RoutineEventContext]
    let weekday: Weekday
    let settings: Settings

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var calendarStore: CalendarService
    @EnvironmentObject private var plannerService: PlannerService
    @EnvironmentObject private var todayService: TodayService

    @StateObject private var routineEngine = ListEngine<RoutineEventContext>()

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
                        sortedItems: sortedRoutineEventContexts,
                        itemsLabel: "\(weekday.label) Routine",
                        createItem: createEvent,
                        moveItem: moveEvent,
                        deleteItem: deleteEvent,
                        handleTitleChange: handleEventTitleChange,
                        tint: { _ in accentColor.swiftUiColor },
                        toggleConfig: eventToggleConfig,
                        leftAdornment: { _ in EmptyView() },
                        rightAdornment: timeAdornment,
                        bottomAdornment: weekdaysAdornment,
                        scrollProxy: scrollProxy,
                        namespace: namespace
                    )
                    .safeAreaBar(edge: .bottom) {
                        actionToolbar(scrollProxy: scrollProxy)
                    }
                    .toolbar {
                        topLeadingToolbar
                        topTrailingToolbar
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
                    sortedSourceRoutineEvents: sortedRoutineEventContexts,
                    settings: settings,
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
                    sourceWeekday: weekday,
                    sourceSortedRoutineEvents: sortedRoutineEventContexts,
                    settings: settings,
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
                    routine: routine,
                    routineEvents: sortedRoutineEventContexts,
                    weekday: weekday,
                    settings: settings
                )
            } else {
                SelectAllToggleView(visibleItems: sortedRoutineEventContexts)
            }
        }
    }

    // MARK: - View Builders

    @ViewBuilder
    private func timeAdornment(event: RoutineEventContext) -> some View {
        if let time = event.time {
            Time(
                timeInRegion: DateInRegion(time, region: .UTC),
                onTap: {
                    openRoutineEventSheet(for: event)
                }
            )
        }
    }

    @ViewBuilder
    private func weekdaysAdornment(event: RoutineEventContext) -> some View {
        if event.weekdays.count > 1 {
            WeekdaySpreadView(
                selected: event.weekdays
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                openRoutineEventSheet(for: event)
            }
        }
    }

    private func actionToolbar(scrollProxy: ScrollViewProxy) -> some View {
        ListActionToolbarView<
            RoutineEventContext,
            SelectedRoutineEventActionsView
        >(
            keyboardAccessory: ListKeyboardAccessoryView(
                items: sortedRoutineEventContexts,
                iconImageNames: ["info"],
                onIconTap: handleToolbarTap
            ),
            selectedItemActions: SelectedRoutineEventActionsView(
                showTransferSheet: $showTransferSheet,
                routine: routine,
                weekday: weekday,
                namespace: namespace,
                settings: settings
            ),
            createItem: {
                createLowerEvent(scrollProxy: scrollProxy)
            }
        )
    }

    // MARK: - Functions

    private func createEvent(at index: Int) {
        routineEngine.pendingFocusId = modelContext.createRoutineEventContext(
            at: index,
            in: sortedRoutineEventContexts,
            routine: routine
        )
    }

    private func moveEvent(from: Int, to: Int) {
        modelContext.moveRoutineEvent(
            from: from,
            to: to,
            sortedRoutineEventContexts: sortedRoutineEventContexts,
            routine: routine
        )
        plannerService.invalidateRoutines()
    }

    private func deleteEvent(_ routineEventContext: RoutineEventContext) {
        _ = modelContext.deleteRoutineEventContext(
            routineEventContext,
            todayStartOfDay: todayService.todayPlanner.startOfDay(
                settings: settings
            ),
            ekEventStore: calendarStore.ekEventStore
        )
    }

    private func handleEventTitleChange(event: RoutineEventContext) {
        if !invalidatedEventIds.contains(event.stableId) {
            event.version += 0.1

            // Mark routines for refresh in the planners.
            plannerService.invalidateRoutines()
            invalidatedEventIds.insert(event.stableId)
        }

        modelContext.handleRoutineEventContextTitleChange(event)
    }

    private func handleToolbarTap(icon _: String, event: RoutineEventContext) {
        openRoutineEventSheet(for: event)
    }

    private func eventToggleConfig(_ event: RoutineEventContext)
        -> ToggleConfig?
    {
        ToggleConfig(
            pendingIconConfig: IconConfig(
                name: "minus.circle",
                primaryColor: Color.red,
                secondaryColor: Color.tertiary
            ),
            completedIconConfig: IconConfig(name: ""),
            confirmation: removeRoutineEventFromWeekdayConfig(
                routineEventContext: event,
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
        createEvent(at: sortedRoutineEventContexts.count)
        scrollProxy.scrollToBottomOfList()
    }

    private func openRoutine(for weekday: Weekday) {
        routineCoverContext = weekday
    }

    private func openRoutineEventSheet(for event: RoutineEventContext) {
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

    private func removeEventFromWeekday(_ event: RoutineEventContext) {
        modelContext.removeRoutineEventContextsFromRoutine(
            routineEventContexts: [event],
            routine: routine,
            todayStartOfDay: todayService.todayPlanner.startOfDay(
                settings: settings
            ),
            ekEventStore: calendarStore.ekEventStore
        )
    }

    private func deleteEventEverywhere(
        _ routineEventContext: RoutineEventContext
    ) {
        _ = modelContext.deleteRoutineEventContext(
            routineEventContext,
            todayStartOfDay: todayService.todayPlanner.startOfDay(
                settings: settings
            ),
            ekEventStore: calendarStore.ekEventStore
        )
    }
}
