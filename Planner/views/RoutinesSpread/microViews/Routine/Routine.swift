//
//  Routine.swift
//  Planner
//
//  Created by Alex Green on 4/5/26.
//

import SwiftData
import SwiftUI

struct RoutineEventSheetContext: Identifiable {
    var routineEvent: RoutineEvent
    var neighborIds: NeighborIds

    var id: String {
        routineEvent.stableId.uuidString
    }
}

struct RoutineView: View {
    let dayOfWeek: DayOfWeek
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
                    bottomAdornment: recurringAdornment,
                    handleTitleChange: modelContext
                        .handleRoutineEventTitleChange
                )
                .navigationTitle(dayOfWeek.rawValue.capitalizedFirst)
                .navigationSubtitle("Recurring Events")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    upperLeftToolbar
                    upperRightToolbar
                    lowerToolbar(scrollProxy: scrollProxy)
                }
                .animateSynchronousAction(from: routineManager.isSelectMode)
            }
        }
        .overlay {
            NotificationsView()
        }

        // MARK: Routine Event Sheet
        .sheet(item: $routineEventSheetContext) { context in
            RoutineEventFormView(
                sourceRoutineEvent: context.routineEvent,
                sourceDayOfWeek: dayOfWeek,
                sourceNeighborIds: context.neighborIds
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
                sourceDayOfWeek: dayOfWeek
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

    // MARK: Upper Left Toolbar

    @ToolbarContentBuilder
    private var upperLeftToolbar: some ToolbarContent {
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

    // MARK: Upper Right Toolbar

    @ToolbarContentBuilder
    private var upperRightToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if !routineManager.isSelectMode {
                RoutineActionMenuView(
                    dayOfWeek: dayOfWeek,
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

    // MARK: Lower Toolbar

    @ToolbarContentBuilder
    private func lowerToolbar(scrollProxy: ScrollViewProxy)
        -> some ToolbarContent
    {
        ToolbarItemGroup(placement: .bottomBar) {
            if !routineManager.isSelectMode {
                Spacer()
                createLowerEventButton(scrollProxy: scrollProxy)
            } else {
                SelectedRoutineEventActionsView(
                    showTransferSheet: $showTransferSheet,
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

    @ViewBuilder
    private func timeAdornment(event: RoutineEvent) -> some View {
        event.timeAdornment(
            dayOfWeek: dayOfWeek,
            accentColor: accentColor
        ) {
            openRoutineEventSheet(for: event)
        }
    }

    @ViewBuilder
    private func recurringAdornment(event: RoutineEvent) -> some View {
        event.recurringAdornment {
            openRoutineEventSheet(for: event)
        }
    }

    // MARK: - Functions

    private func createEvent(at index: Int) {
        routineManager.pendingFocusId = modelContext.createRoutineEvent(
            at: index,
            in: sortedRoutineEvents,
            dayOfWeek: dayOfWeek
        )
    }

    private func moveEvent(from: Int, to: Int) {
        modelContext.moveRoutineEvent(
            from: from,
            to: to,
            on: dayOfWeek,
            sortedEvents: sortedRoutineEvents
        )
    }

    private func openRoutineEventSheet(for event: RoutineEvent) {
        if routineManager.isSelectMode {
            routineManager.toggleItem(event)
            return
        }

        let neighborIds = event.getNeighborIds(in: sortedRoutineEvents)

        routineManager.protectedId = event.stableId
        routineManager.focusedId = nil
        routineEventSheetContext = RoutineEventSheetContext(
            routineEvent: event,
            neighborIds: neighborIds
        )
    }

    private func createLowerEvent(scrollProxy: ScrollViewProxy) {
        createEvent(at: sortedRoutineEvents.count)
        scrollToBottom(scrollProxy: scrollProxy)
    }

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
                    "This will delete all occurrences of the event from your routines and planner. This action cannot be undone.",
                needsConfirmation: { _ in true },
                actions: [
                    ConfirmationAction(
                        title: "Confirm",
                        role: .destructive
                    ) { event in
                        modelContext.deleteRoutineEvents([event])
                    }
                ]
            )
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
