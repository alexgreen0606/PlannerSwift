//
//  ChecklistActionMenu.swift
//  Planner
//
//  Created by Alex Green on 3/9/26.
//

import SwiftData
import SwiftUI

struct ChecklistActionMenuView: View {
    @Binding var showEditSheet: Bool
    let checklist: ChecklistItem
    let items: [ChecklistItem]
    let visibleItems: [ChecklistItem]

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var listEngine: ListEngine<ChecklistItem>

    @State private var showDeleteCompletedConfirmation = false
    @State private var showDeleteChecklistConfirmation = false

    private var completedItems: [ChecklistItem] {
        items.filter(\.isCompleted)
    }

    private var deleteCompletedConfig: ConfirmationConfig {
        bulkDeleteCompletedChecklistItemConfig(
            completedItems: completedItems,
            item: checklist,
            delete: deleteCompletedItems
        )
    }

    private var deleteChecklistConfig: ConfirmationConfig {
        deleteChecklistItemConfig(
            item: checklist,
            delete: deleteEntireChecklist
        )
    }

    private var completedItemExists: Bool {
        !completedItems.isEmpty
    }

    // MARK: - Body

    var body: some View {
        Menu("Checklist Action Menu", systemImage: "ellipsis") {
            ToggleCompletedVisibilityView(
                showCompleted: checklist.showCompleted,
                toggle: { checklist.showCompleted.toggle() }
            )

            SelectItemsButtonView<ChecklistItem>(
                hasVisibleItem: !visibleItems.isEmpty
            )

            editChecklistButton
            deleteActionMenu
        }

        // MARK: Delete Completed Confirmation
        .withConfirmation(
            deleteCompletedConfig,
            isPresented: $showDeleteCompletedConfirmation
        )

        // MARK: Delete Checklist Confirmation
        .withConfirmation(
            deleteChecklistConfig,
            isPresented: $showDeleteChecklistConfirmation
        )
    }

    // MARK: - View Builders

    // MARK: Edit Checklist Button
    private var editChecklistButton: some View {
        Button {
            showEditSheet = true
        } label: {
            Label(
                "Edit Checklist",
                systemImage: "pencil"
            )
        }
    }

    // MARK: Delete Action Menu

    private var deleteActionMenu: some View {
        Menu {
            deleteCompletedItemsButton
            deleteListButton
        } label: {
            Label(
                "Delete Options",
                systemImage: "trash"
            )
        }
    }

    private var deleteCompletedItemsButton: some View {
        Button(role: .destructive) {
            showDeleteCompletedConfirmation = true
        } label: {
            Text("Delete Completed")
        }
        .disabled(!completedItemExists)
    }

    private var deleteListButton: some View {
        Button(role: .destructive) {
            showDeleteChecklistConfirmation = true
        } label: {
            Text("Delete Checklist")
        }
    }

    // MARK: - Functions

    private func deleteCompletedItems() {
        modelContext.deleteChecklistItems(completedItems)
    }

    private func deleteEntireChecklist() {
        DispatchQueue.main.async {
            dismiss()

            DispatchQueue.main.async {
                modelContext.safeDelete(checklist)
            }
        }
    }
}
