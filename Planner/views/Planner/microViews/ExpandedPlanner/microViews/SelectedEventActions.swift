//
//  SelectedEventActions.swift
//  Planner
//
//  Created by Alex Green on 3/11/26.
//

import SwiftData
import SwiftUI

// Clean

struct SelectedEventActionsView: View {
    @Binding var showTransferSheet: Bool
    let namespace: Namespace.ID

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var calendarStore: CalendarStore
    @EnvironmentObject private var plannerManager: ListManager<PlannerEvent>

    var body: some View {
        DeleteSelectedButtonView(
            itemsLabel: "events",
            disabled: plannerManager.selectedItemIds.isEmpty,
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
            ekEventStore: calendarStore.ekEventStore
        )

        DispatchQueue.main.async(execute: plannerManager.toggleSelectMode)
    }

}
