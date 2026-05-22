//
//  SelectedChecklistItemActions.swift
//  Planner
//
//  Created by Alex Green on 4/16/26.
//

import SwiftData
import SwiftUI

struct SelectedChecklistItemActionsView: ToolbarContent {
    @Binding var showTransferSheet: Bool
    let canTransferItems: Bool
    let parentType: ChecklistItemType
    let namespace: Namespace.ID

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var listEngine: ListEngine<ChecklistItem>

    private var deleteConfirmation: ConfirmationConfig {
        bulkDeleteChecklistItemConfig(
            items: listEngine.selectedItems,
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
            disabled: listEngine.selectedItems.isEmpty
        )
    }

    @ViewBuilder
    private var transferSelectedButton: some View {
        TransferSelectedButtonView<ChecklistItem>(
            showTransferSheet: $showTransferSheet,
            systemImage: parentType == .folder
                ? "arrow.forward.folder" : "arrow.left.arrow.right",
            disabled: !canTransferItems,
            namespace: namespace
        )
    }

    // MARK: - Functions

    private func deleteSelectedItems() {
        let selections = listEngine.selectedItems

        listEngine.clearSelections()

        DispatchQueue.main.async {
            modelContext.deleteChecklistItems(
                selections
            )

            DispatchQueue.main.async(execute: listEngine.toggleSelectMode)
        }
    }
}
