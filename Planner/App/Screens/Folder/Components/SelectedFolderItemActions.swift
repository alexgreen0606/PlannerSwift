//
//  SelectedFolderItemActions.swift
//  Planner
//
//  Created by Alex Green on 4/16/26.
//

import SwiftData
import SwiftUI

struct SelectedFolderItemActionsView: ToolbarContent {
    @Binding var showTransferSheet: Bool
    let items: [ChecklistItem]
    let canTransferItems: Bool
    let namespace: Namespace.ID

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var listEngine: ListEngine<ChecklistItem>

    @State private var showDeleteConfirmation = false

    private var deleteConfirmation: ConfirmationConfig {
        bulkDeleteChecklistItemsConfig(
            items: listEngine.selectedItems,
            delete: deleteSelectedItems
        )
    }

    // MARK: - Body

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            SelectAllToggleView(visibleItems: items)
        }

        ToolbarSpacer(.fixed, placement: .topBarTrailing)

        ToolbarItem(placement: .topBarTrailing) {
            deleteSelectedButton
        }

        ToolbarSpacer(.fixed, placement: .topBarTrailing)

        ToolbarItem(placement: .topBarTrailing) {
            transferSelectedButton
        }
    }

    // MARK: - View Builders

    private var deleteSelectedButton: some View {
        Button("", systemImage: "trash") {
            showDeleteConfirmation = true
        }
        .disabled(listEngine.selectedItemIds.isEmpty)
        .tint(Color.label)
        .withConfirmation(
            deleteConfirmation,
            isPresented: $showDeleteConfirmation
        )
    }

    private var transferSelectedButton: some View {
        Button(
            "",
            systemImage: "arrow.forward.folder"
        ) {
            showTransferSheet = true
        }
        .disabled(!canTransferItems || listEngine.selectedItemIds.isEmpty)
        .matchedTransitionSource(
            id: ListIds.TRANSFER_BUTTON,
            in: namespace
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
