//
//  ChecklistActionMenu.swift
//  Planner
//
//  Created by Alex Green on 3/9/26.
//

import SwiftData
import SwiftUI

// Clean

struct ChecklistActionMenu: View {
    @Binding var isEditSheetOpen: Bool
    let checklist: ChecklistItem
    let hasCheckedItem: Bool
    let completedItems: [ChecklistItem]
    let visibleItems: [ChecklistItem]

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var listManager: ListManager<ChecklistItem>

    @State private var showDeleteCompletedConfirmation = false
    @State private var showDeleteChecklistConfirmation = false

    private var deleteCompletedConfirmationConfig: ConfirmationConfig {
        ConfirmationConfig(
            title:
                "Delete completed \("item".pluralized(from: completedItems.count)) from \"\(checklist.title)\"?",
            message:
                "\(completedItems.count) \("item".pluralized(from: completedItems.count)) will be deleted from this checklist. \(genericDeleteWarning)",
            actions: [
                ConfirmationAction(
                    title:
                        "Delete \(completedItems.count) \("Item".pluralized(from: completedItems.count))",
                    handler: deleteCompletedItems
                )
            ]
        )
    }

    private var checklistDeleteConfirmation: ConfirmationConfig {
        singleDeleteChecklistItemConfig(
            item: checklist,
            delete: deleteEntireChecklist
        )
    }

    // MARK: - Body

    var body: some View {
        Menu("Action Menu", systemImage: "ellipsis") {
            showCompletedToggle
            editChecklistButton
            selectItemsButton
            deleteActionMenu
        }

        // MARK: Delete Completed Confirmation
        .withConfirmation(
            deleteCompletedConfirmationConfig,
            isPresented: $showDeleteCompletedConfirmation
        )

        // MARK: Delete Checklist Confirmation
        .withConfirmation(
            checklistDeleteConfirmation,
            isPresented: $showDeleteChecklistConfirmation
        )
    }

    // MARK: - View Builders

    private var showCompletedToggle: some View {
        Button {
            checklist.showCompleted.toggle()
        } label: {
            Label(
                checklist.showCompleted
                    ? "Hide Completed"
                    : "Show Completed",
                systemImage: checklist.showCompleted
                    ? "eye.slash" : "eye"
            )
        }
    }

    private var editChecklistButton: some View {
        Button {
            isEditSheetOpen = true
        } label: {
            Label(
                "Edit Checklist",
                systemImage: "pencil"
            )
        }
    }

    private var selectItemsButton: some View {
        Button {
            listManager.toggleSelectMode()
        } label: {
            Label(
                "Select Items",
                systemImage: "checkmark.circle"
            )
        }
        .disabled(visibleItems.isEmpty)
    }

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
        .disabled(!hasCheckedItem)
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
        dismiss()
        modelContext.safeDelete(checklist)
    }

}
