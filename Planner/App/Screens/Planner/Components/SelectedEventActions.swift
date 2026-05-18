//
//  SelectedEventActions.swift
//  Planner
//
//  Created by Alex Green on 3/11/26.
//

import SwiftData
import SwiftUI

// Clean

struct SelectedPlannerEventActionsView: ToolbarContent {
    @Binding var showTransferSheet: Bool
    let planner: Planner
    let namespace: Namespace.ID

    @Environment(\.modelContext) private var modelContext
    @Environment(\.showToast) private var showToast
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var plannerManager: ListEngine<PlannerEvent>

    private var deleteConfig: ConfirmationConfig {
        bulkDeletePlannerEventConfig(
            events: plannerManager.selectedItems,
            delete: deleteSelectedEvents
        )
    }

    // MARK: - Body

    var body: some ToolbarContent {
        ToolbarItem(placement: .bottomBar) {
            deleteSelectedButton
        }

        ToolbarSpacer(placement: .bottomBar)

        ToolbarItem(placement: .bottomBar) {
            transferSelectedButton
        }
    }

    // MARK: - View Builders

    private var deleteSelectedButton: some View {
        DeleteSelectedButtonView(
            confirmationConfig: deleteConfig,
            disabled: plannerManager.selectedItemIds.isEmpty
        )
    }

    private var transferSelectedButton: some View {
        Button(
            "Transfer",
            systemImage: "arrow.left.arrow.right"
        ) {
            showTransferSheet = true
        }
        .disabled(plannerManager.selectedItemIds.isEmpty)
        .matchedTransitionSource(
            id: ListIds.TRANSFER_BUTTON,
            in: namespace
        )
    }

    // MARK: - Functions

    private func deleteSelectedEvents() {
        modelContext.deletePlannerEvents(
            plannerManager.selectedItems,
            in: planner,
            ekEventStore: calendarStore.ekEventStore
        )

        DispatchQueue.main.async(execute: plannerManager.toggleSelectMode)
    }
}
