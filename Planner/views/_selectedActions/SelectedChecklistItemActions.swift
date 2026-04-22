//
//  SelectedChecklistItemActions.swift
//  Planner
//
//  Created by Alex Green on 4/16/26.
//

import SwiftData
import SwiftUI

// Clean

struct SelectedChecklistItemActionsView: ToolbarContent {
    @Binding var showTransferSheet: Bool
    let canTransferItems: Bool
    let parentType: ChecklistItemType
    let namespace: Namespace.ID

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var listManager: ListManager<ChecklistItem>

    private var deleteConfirmation: ConfirmationConfig {
        bulkDeleteChecklistItemConfig(
            items: listManager.selectedItems,
            delete: deleteSelectedItems
        )
    }

    // MARK: - Body

    var body: some ToolbarContent {
        if parentType == .checklist {
            ToolbarItem(placement: .bottomBar) {
                deleteSelectedButton
            }

            ToolbarSpacer(placement: .bottomBar)

            ToolbarItem(placement: .bottomBar) {
                transferSelectedButton
            }
        } else {
            ToolbarItem(placement: .topBarTrailing) {
                deleteSelectedButton
            }

            ToolbarSpacer(.fixed, placement: .topBarTrailing)

            ToolbarItem(placement: .topBarTrailing) {
                transferSelectedButton
            }
        }
    }

    // MARK: - View Builders

    private var deleteSelectedButton: some View {
        DeleteSelectedButtonView(
            confirmationConfig: deleteConfirmation,
            disabled: listManager.selectedItems.isEmpty
        )
    }

    @ViewBuilder
    private var transferSelectedButton: some View {
        let icon =
            parentType == .checklist
            ? "arrow.left.arrow.right" : "arrow.forward.folder"
        
        Button(
            "Transfer",
            systemImage: icon
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
