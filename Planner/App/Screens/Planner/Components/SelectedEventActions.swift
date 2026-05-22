//
//  SelectedEventActions.swift
//  Planner
//
//  Created by Alex Green on 3/11/26.
//

import SwiftData
import SwiftUI

struct SelectedEventActionsView: ToolbarContent {
    @Binding var showTransferSheet: Bool
    let planner: Planner
    let namespace: Namespace.ID

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var plannerEngine: ListEngine<PlannerEvent>

    private var deleteConfig: ConfirmationConfig {
        bulkDeletePlannerEventConfig(
            events: plannerEngine.selectedItems,
            delete: deleteSelectedEvents
        )
    }

    // MARK: - Body

    var body: some ToolbarContent {
        ToolbarItem(placement: .bottomBar) {
            DeleteSelectedButtonView(
                confirmationConfig: deleteConfig,
                disabled: plannerEngine.selectedItemIds.isEmpty
            )
        }

        ToolbarSpacer(placement: .bottomBar)

        ToolbarItem(placement: .bottomBar) {
            TransferSelectedButtonView<PlannerEvent>(
                showTransferSheet: $showTransferSheet,
                namespace: namespace
            )
        }
    }

    // MARK: - Functions

    private func deleteSelectedEvents() {
        let selections = plannerEngine.selectedItems

        plannerEngine.clearSelections()

        DispatchQueue.main.async {
            modelContext.deletePlannerEvents(
                selections,
                in: planner,
                ekEventStore: calendarStore.ekEventStore
            )

            DispatchQueue.main.async(execute: plannerEngine.toggleSelectMode)
        }
    }
}
