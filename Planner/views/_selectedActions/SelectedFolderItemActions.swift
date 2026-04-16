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
    let canTransferItems: Bool
    let namespace: Namespace.ID

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var listManager: ListManager<ChecklistItem>

    private var selectedItemsLabel: String {
        let items = listManager.selectedItems

        guard let firstType = items.first?.type else {
            return "item"
        }

        let allSameType = items.allSatisfy { $0.type == firstType }

        return allSameType ? firstType.rawValue : "item"
    }

    var body: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            DeleteSelectedButtonView(
                itemLabel: selectedItemsLabel,
                count: listManager.selectedItemIds.count,
                delete: deleteSelectedItems
            )
        }

        ToolbarSpacer(.fixed, placement: .topBarTrailing)

        ToolbarItem(placement: .topBarTrailing) {
            transferItemsButton
        }
    }

    // MARK: - View Builders

    private var deleteSelectedButton: some View {
        DeleteSelectedButtonView(
            itemLabel: selectedItemsLabel,
            count: listManager.selectedItems.count,
            delete: deleteSelectedItems
        )
    }

    private var transferItemsButton: some View {
        Button(
            "Transfer",
            systemImage: "arrow.forward.folder"
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
