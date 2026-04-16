//
//  SelectedChecklistItemActions.swift
//  Planner
//
//  Created by Alex Green on 4/16/26.
//

import SwiftData
import SwiftUI

struct SelectedChecklistItemActionsView: View {
    @Binding var showTransferSheet: Bool
    let canTransferItems: Bool
    let namespace: Namespace.ID

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var listManager: ListManager<ChecklistItem>

    var body: some View {
        deleteSelectedButton
        Spacer()
        transferSelectedButton
    }

    // MARK: - View Builders

    private var deleteSelectedButton: some View {
        DeleteSelectedButtonView(
            itemLabel: "item",
            count: listManager.selectedItems.count,
            delete: deleteSelectedItems
        )
    }

    private var transferSelectedButton: some View {
        Button(
            "Transfer",
            systemImage: "arrow.left.arrow.right"
        ) {
            showTransferSheet = true
        }
        .disabled(
            !canTransferItems || listManager.selectedItemIds.isEmpty
        )
        .matchedTransitionSource(
            id: IdConstants.TRANSFER_BUTTON,
            in: namespace
        )
    }

    // MARK: - Functions

    private func deleteSelectedItems() {
        modelContext.deleteChecklistItems(
            listManager.selectedItems
        )

        DispatchQueue.main.async(execute: listManager.toggleSelectMode)
    }

}
