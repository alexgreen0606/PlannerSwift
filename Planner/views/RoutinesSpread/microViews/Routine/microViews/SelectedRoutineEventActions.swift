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
    let weekday: Weekday
    let namespace: Namespace.ID

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var routineManager: ListManager<RoutineEvent>

    var body: some View {
        DeleteSelectedButtonView(
            itemsLabel: "recurring events",
            disabled: routineManager.selectedItemIds.isEmpty,
            message:
                "Future occurrences will be deleted from \(weekday.label)s. Other days will not be affected.",
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
        .tint(Color.label)
        .disabled(routineManager.selectedItemIds.isEmpty)
        .matchedTransitionSource(
            id: IdConstants.TRANSFER_BUTTON,
            in: namespace
        )
    }

    // MARK: - Functions

    private func deleteSelectedEvents() {
        modelContext.deleteRoutineEvents(
            from: routineManager.selectedItems,
            for: weekday
        )

        DispatchQueue.main.async {
            routineManager.toggleSelectMode()
        }
    }

}
