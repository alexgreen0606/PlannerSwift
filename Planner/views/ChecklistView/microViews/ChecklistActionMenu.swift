//
//  ChecklistActionMenu.swift
//  Planner
//
//  Created by Alex Green on 3/9/26.
//

import SwiftUI

// Clean

struct ChecklistActionMenu: View {
    @Binding var isEditSheetOpen: Bool
    let checklist: ChecklistItem
    let namespace: Namespace.ID
    let hasCheckedItem: Bool
    let completedItems: [ChecklistItem]
    let visibleItems: [ChecklistItem]

    // Can pass a folder to navigate into (passes itself when it is transformed into a folder).
    let closeChecklist: (ChecklistItem?) -> Void

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var listManager: ListManager<ChecklistItem>

    @State private var showDeleteCompletedConfirm = false
    @State private var showDeleteChecklistConfirm = false

    var body: some View {
        Menu("Action Menu", systemImage: "ellipsis") {
            showCompletedToggle
            editChecklistButton
            selectItemsButton
            deleteActionMenu
        }
        .matchedTransitionSource(
            id: IdConstants.ELLIPSIS_BUTTON,
            in: namespace
        )
        .confirmationDialog(
            checklist.deleteConfirmation,
            isPresented: $showDeleteChecklistConfirm,
            titleVisibility: .visible
        ) {
            Button(
                "Confirm",
                role: .destructive,
                action: deleteEntireChecklist
            )
        } message: {
            Text(
                checklist.deleteWarning
            )
        }
        .confirmationDialog(
            "Delete completed items from this list?",
            isPresented: $showDeleteCompletedConfirm,
            titleVisibility: .visible
        ) {
            Button(
                "Confirm",
                role: .destructive,
                action: deleteCompletedItems
            )
        } message: {
            Text("This action is irreversible.")
        }
    }

    // MARK: - View Builders

    private var editChecklistButton: some View {
        Button {
            isEditSheetOpen = true
        } label: {
            Label(
                "Edit checklist",
                systemImage: "pencil"
            )
        }
    }

    private var selectItemsButton: some View {
        Button {
            listManager.toggleSelectMode()
        } label: {
            Label(
                "Select items",
                systemImage: "checkmark.circle"
            )
        }
        .disabled(visibleItems.isEmpty)
    }

    private var showCompletedToggle: some View {
        Button {
            checklist.showCompleted.toggle()
        } label: {
            Label(
                checklist.showCompleted
                    ? "Hide completed"
                    : "Show completed",
                systemImage: checklist.showCompleted
                    ? "eye.slash" : "eye"
            )
        }
    }

    private var deleteActionMenu: some View {
        Menu {
            Button(role: .destructive) {
                showDeleteCompletedConfirm = true
            } label: {
                Text("Delete completed items")
            }
            .disabled(!hasCheckedItem)

            Button(role: .destructive) {
                showDeleteChecklistConfirm = true
            } label: {
                Text("Delete this list")
            }
        } label: {
            Label(
                "Delete options",
                systemImage: "trash"
            )
        }
    }

    // MARK: - Functions

    private func deleteCompletedItems() {
        modelContext.deleteChecklistItems(completedItems)
    }

    private func deleteEntireChecklist() {
        closeChecklist(nil)
        modelContext.deleteChecklistItem(checklist)
    }

}
