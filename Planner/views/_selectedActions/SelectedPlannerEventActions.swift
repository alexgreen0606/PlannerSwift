//
//  SelectedPlannerEventActions.swift
//  Planner
//
//  Created by Alex Green on 3/11/26.
//

import SwiftData
import SwiftUI

// Clean

struct SelectedPlannerEventActionsView: View {
    @Binding var showTransferSheet: Bool
    let planner: Planner
    let namespace: Namespace.ID

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var plannerManager: ListManager<PlannerEvent>

    var body: some View {
        DeleteSelectedButtonView(
            itemLabel: "event",
            count: plannerManager.selectedItemIds.count,
            message:
                "Calendar and planner events will be lost.",
            delete: deleteSelectedEvents
        )
        Spacer()
        transferSelectedButton
    }

    // MARK: - View Builders

    private var transferSelectedButton: some View {
        Button(
            "Transfer",
            systemImage: "arrow.left.arrow.right"
        ) {
            showTransferSheet = true
        }
        .disabled(plannerManager.selectedItemIds.isEmpty)
        .matchedTransitionSource(
            id: IdConstants.TRANSFER_BUTTON,
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
