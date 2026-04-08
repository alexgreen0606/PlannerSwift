//
//  SelectedRoutineEventActions.swift
//  Planner
//
//  Created by Alex Green on 4/7/26.
//

import SwiftData
import SwiftUI

// Clean

struct SelectedRoutineEventActionsView: View {
    @Binding var showTransferSheet: Bool
    let namespace: Namespace.ID

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var routineManager: ListManager<RoutineEvent>

    var body: some View {
        DeleteSelectedButtonView(
            itemsLabel: "recurring events",
            disabled: routineManager.selectedItemIds.isEmpty,
            message:
                "This will delete all occurrences of the events from your routines and planner.",
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
        .disabled(routineManager.selectedItemIds.isEmpty)
        .matchedTransitionSource(
            id: IdConstants.TRANSFER_BUTTON,
            in: namespace
        )
    }

    // MARK: - Functions

    private func deleteSelectedEvents() {
        modelContext.deleteRoutineEvents(routineManager.selectedItems)

        DispatchQueue.main.async {
            routineManager.toggleSelectMode()
        }
    }

}
