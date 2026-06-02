//
//  SelectedItemActions.swift
//  Planner
//
//  Created by Alex Green on 5/28/26.
//

import SwiftData
import SwiftUI

struct SelectedItemActionsView: View {
    @Binding var showTransferSheet: Bool
    let canTransferItems: Bool
    let namespace: Namespace.ID

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var listEngine: ListEngine<ChecklistItem>

    private var deleteConfirmation: ConfirmationConfig {
        bulkDeleteChecklistItemsConfig(
            items: listEngine.selectedItems,
            delete: deleteSelectedItems
        )
    }

    // MARK: - Body

    var body: some View {
        deleteSelectedButton

        Spacer()

        transferSelectedButton
    }

    // MARK: - View Builders

    private var deleteSelectedButton: some View {
        DeleteSelectedButtonView<ChecklistItem>(
            confirmationConfig: deleteConfirmation
        )
    }

    private var transferSelectedButton: some View {
        TransferSelectedButtonView<ChecklistItem>(
            showTransferSheet: $showTransferSheet,
            systemImage: "arrow.left.arrow.right",
            disabled: !canTransferItems,
            namespace: namespace
        )
    }

    // MARK: - Functions

    private func deleteSelectedItems() {
        let selections = listEngine.selectedItems

        listEngine.clearSelections()

        DispatchQueue.main.async {
            modelContext.safeBulkDelete(
                selections
            )

            DispatchQueue.main.async(execute: listEngine.toggleSelectMode)
        }
    }
}
