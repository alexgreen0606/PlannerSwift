//
//  SelectedRoutineEventActions.swift
//  Planner
//
//  Created by Alex Green on 4/7/26.
//

import SwiftData
import SwiftUI

struct SelectedRoutineEventActionsView: ToolbarContent {
    @Binding var showTransferSheet: Bool
    let weekday: Weekday
    let namespace: Namespace.ID

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var routineEngine: ListEngine<RoutineEvent>
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var plannerSyncService: PlannerSyncService

    @State private var showDeleteConfirmation = false

    private var deleteConfirmation: ConfirmationConfig {
        bulkRemoveRoutineEventFromWeekdayConfig(
            events: routineEngine.selectedItems,
            weekday: weekday,
            remove: deleteSelectedEventsFromWeekday,
            delete: deleteSelectedEventsEverywhere
        )
    }

    // MARK: - Body

    var body: some ToolbarContent {
        ToolbarItem(placement: .bottomBar) {
            DeleteSelectedButtonView<RoutineEvent>(
                confirmationConfig: deleteConfirmation
            )
        }

        ToolbarSpacer(placement: .bottomBar)

        ToolbarItem(placement: .bottomBar) {
            TransferSelectedButtonView<RoutineEvent>(
                showTransferSheet: $showTransferSheet,
                namespace: namespace
            )
        }
    }

    // MARK: - Functions

    private func deleteSelectedEventsFromWeekday() {
        let selections = routineEngine.selectedItems

        routineEngine.clearSelections()

        DispatchQueue.main.async {
            modelContext.deleteRoutineEvents(
                selections,
                from: weekday,
                ekEventStore: calendarStore.ekEventStore,
                PlannerSyncStore: plannerSyncService
            )

            DispatchQueue.main.async(execute: routineEngine.toggleSelectMode)
        }
    }

    private func deleteSelectedEventsEverywhere() {
        let selections = routineEngine.selectedItems

        routineEngine.clearSelections()

        DispatchQueue.main.async {
            modelContext.deleteRoutineEvents(
                selections,
                ekEventStore: calendarStore.ekEventStore,
                PlannerSyncStore: plannerSyncService
            )

            DispatchQueue.main.async(execute: routineEngine.toggleSelectMode)
        }
    }
}
