//
//  Routine.swift
//  Planner
//
//  Created by Alex Green on 4/5/26.
//

import SwiftData
import SwiftUI

// Clean

struct RoutineEventSheetContext: Identifiable {
    var routineEvent: RoutineEvent

    var id: String {
        routineEvent.stableId.uuidString
    }
}

struct RoutineView: View {
    @Binding var routineCoverContext: RoutineCoverContext?
    let weekday: Weekday
    let sortedRoutineEvents: [RoutineEvent]

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var routineManager = ListManager<RoutineEvent>()
    @State private var showTransferSheet = false
    @State private var routineEventSheetContext: RoutineEventSheetContext? = nil

    @Namespace private var namespace

    private var isAllSelected: Bool {
        !sortedRoutineEvents.isEmpty
            && routineManager.selectedItemIds.count == sortedRoutineEvents.count
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { scrollProxy in
                SortableListView(
                    uncheckedItems: sortedRoutineEvents,
                    emptyUncheckedLabel: "No recurring events",
                    tint: { _ in accentColor.color },
                    createItem: createEvent,
                    moveItem: moveEvent,
                    namespace: namespace,
                    toolbarSystemImageNames: [
                        "rectangle.and.pencil.and.ellipsis"
                    ],
                    onToolbarTap: { _, event in
                        openRoutineEventSheet(for: event)
                    },
                    toggleConfig: eventToggleConfig,
                    leftAdornment: { _ in EmptyView() },
                    rightAdornment: timeAdornment,
                    bottomAdornment: weekdaysAdornment,
                    handleTitleChange: modelContext
                        .handleRoutineEventTitleChange
                )
                .navigationTitle(weekday.label)
                .navigationSubtitle("Recurring Events")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    topLeadingToolbar
                    topTrailingToolbar
                    bottomToolbar(scrollProxy: scrollProxy)
                }
                .animateSynchronousAction(from: routineManager.isSelectMode)
            }
        }
        .overlay {
            if !notificationManager.notifications.isEmpty {
                // Note: Must be rendered conditionally within this file.
                // Changes to notifications are sometimes not recognized within the NotificationsView
                // due to overlay restrictions.
                NotificationsView()
                    .transition(
                        .move(edge: .leading).combined(with: .opacity)
                    )
            }
        }

        // MARK: Routine Event Sheet
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
                routineManager.protectedId = nil
            }
        }

        // MARK: Transfer Event Sheet
        .sheet(isPresented: $showTransferSheet) {
            TransferRoutineEventsFormView(
                sourceDayOfWeek: weekday,
                sortedSourceRoutineEvents: sortedRoutineEvents,
                openRoutine: openRoutine
            )
            .navigationTransition(
                .zoom(
                    sourceID: IdConstants.TRANSFER_BUTTON,
                    in: namespace
                )
            )
        }

        // Inject the environment objects last so they can be accessed in the sheets.
        .environmentObject(routineManager)
        .environmentObject(notificationManager)
    }

    // MARK: - Toolbars

    // MARK: Top Left Toolbar

    @ToolbarContentBuilder
    private var topLeadingToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if !routineManager.isSelectMode {
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
            action: routineManager.toggleSelectMode
        )
        // Note: This fixes a bug where opening select mode while a keyboard is open causes this button to
        // appear tinted as the accent color.
        .tint(Color.label)
    }

    // MARK: Top Trailing Toolbar

    @ToolbarContentBuilder
    private var topTrailingToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if !routineManager.isSelectMode {
                RoutineActionMenuView(
                    weekday: weekday,
                    sortedRoutineEvents: sortedRoutineEvents
                )
            } else {
                selectAllToggle
            }
        }
    }

    private var selectAllToggle: some View {
        Button {
            routineManager.toggleSelectAll(visibleItems: sortedRoutineEvents)
        } label: {
            Text(isAllSelected ? "Deselect All" : "Select All")
                .fontWeight(.semibold)
        }
        .disabled(sortedRoutineEvents.isEmpty)
    }

    // MARK: Bottom Toolbar

    @ToolbarContentBuilder
    private func bottomToolbar(scrollProxy: ScrollViewProxy)
        -> some ToolbarContent
    {
        ToolbarItemGroup(placement: .bottomBar) {
            if !routineManager.isSelectMode {
                Spacer()
                createLowerEventButton(scrollProxy: scrollProxy)
            } else {
                SelectedRoutineEventActionsView(
                    showTransferSheet: $showTransferSheet,
                    weekday: weekday,
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

    // MARK: - View Builders

    @ViewBuilder
    private func timeAdornment(event: RoutineEvent) -> some View {
        event.timeAdornment(
            accentColor: accentColor
        ) {
            openRoutineEventSheet(for: event)
        }
    }

    @ViewBuilder
    private func weekdaysAdornment(event: RoutineEvent) -> some View {
        event.weekdaysAdornment {
            openRoutineEventSheet(for: event)
        }
    }

    // MARK: - Functions

    private func createEvent(at index: Int) {
        routineManager.pendingFocusId = modelContext.createRoutineEvent(
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
            sortedEvents: sortedRoutineEvents
        )
    }

    private func openRoutineEventSheet(for event: RoutineEvent) {
        if routineManager.isSelectMode {
            routineManager.toggleItem(event)
            return
        }

        routineManager.protectedId = event.stableId
        routineManager.focusedId = nil
        routineEventSheetContext = RoutineEventSheetContext(
            routineEvent: event
        )
    }

    private func createLowerEvent(scrollProxy: ScrollViewProxy) {
        createEvent(at: sortedRoutineEvents.count)
        scrollToBottom(scrollProxy: scrollProxy)
    }

    private func openRoutine(for weekday: Weekday) {
        routineCoverContext = RoutineCoverContext(weekday: weekday)
    }

    // TODO: event form notifications not working
    // TODO: notifications must be unique to one cover at a time.
    private func eventToggleConfig(_ event: RoutineEvent) -> ToggleConfig<
        RoutineEvent
    >? {
        ToggleConfig<RoutineEvent>(
            iconConfig: IconConfig(name: ""),
            uncheckedIconConfig: IconConfig(
                name: "minus.circle",
                primaryColor: Color.red,
                secondaryColor: Color.tertiary
            ),
            confirmation: ConfirmationConfig<RoutineEvent>(
                title: "Delete recurring event?",
                message:
                    "Future occurrences will be deleted from \(weekday.label)s. Other days will not be affected. This action cannot be undone.",
                needsConfirmation: { _ in true },
                actions: [
                    ConfirmationAction(
                        title: "Confirm",
                        role: .destructive,
                        handler: deleteEventFromWeekday
                    )
                ]
            ),
            onClick: {
                if routineManager.focusedId == event.stableId {
                    routineManager.focusedId = nil
                }
            }
        )
    }

    private func deleteEventFromWeekday(_ event: RoutineEvent) {
        modelContext.deleteRoutineEvents(
            from: [event],
            for: weekday
        )
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
