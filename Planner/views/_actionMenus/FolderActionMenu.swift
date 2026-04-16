//
//  FolderActionMenu.swift
//  Planner
//
//  Created by Alex Green on 4/16/26.
//

import SwiftData
import SwiftUI

// Clean

struct FolderActionMenuView: View {
    @Binding var showEditSheet: Bool
    let folder: ChecklistItem
    let sortedItems: [ChecklistItem]

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var selectManager: ListManager<ChecklistItem>

    @State private var showDeleteFolderConfirm = false

    var body: some View {
        Menu("Action Menu", systemImage: "ellipsis") {
            editFolderButton
            selectItemsButton
            deleteFolderButton
        }
        .confirmationDialog(
            folder.deleteConfirmation,
            isPresented: $showDeleteFolderConfirm,
            titleVisibility: .visible
        ) {
            Button("Confirm", role: .destructive, action: deleteEntireFolder)
        } message: {
            Text(folder.deleteWarning)
        }
    }

    // MARK: - View Builders

    private var editFolderButton: some View {
        Button {
            showEditSheet = true
        } label: {
            Label("Edit Folder", systemImage: "pencil")
        }
    }

    private var selectItemsButton: some View {
        Button {
            selectManager.toggleSelectMode()
        } label: {
            Label("Select Items", systemImage: "checkmark.circle")
        }
        .disabled(sortedItems.isEmpty)
    }

    @ViewBuilder
    private var deleteFolderButton: some View {
        if folder.parent != nil {
            Button(role: .destructive) {
                showDeleteFolderConfirm = true
            } label: {
                Label("Delete Folder", systemImage: "trash")
            }
        }
    }

    // MARK: - Functions

    private func deleteEntireFolder() {
        dismiss()
        modelContext.safeDelete(folder)
    }

}
