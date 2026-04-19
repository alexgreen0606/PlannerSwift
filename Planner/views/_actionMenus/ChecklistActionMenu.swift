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
    @Binding var showEditSheet: Bool
    let checklist: ChecklistItem
    let completedItemExists: Bool
    let completedItems: [ChecklistItem] // TODO: these aren't raw. They are based on UI
    let visibleItems: [ChecklistItem]

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var listManager: ListManager<ChecklistItem>

    @State private var showDeleteCompletedConfirmation = false
    @State private var showDeleteChecklistConfirmation = false

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

    // MARK: - Body

    var body: some View {
        Menu("Action Menu", systemImage: "ellipsis") {
            editChecklistButton
            showCompletedToggle
            selectItemsButton
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
        dismiss()
        modelContext.safeDelete(checklist)
    }

}
