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

    @State private var showDeleteConfirmation = false

    private var deleteFolderConfig: ConfirmationConfig {
        deleteChecklistItemConfig(
            item: folder,
            delete: deleteEntireFolder
        )
    }

    var body: some View {
        Menu("Action Menu", systemImage: "ellipsis") {
            editFolderButton
            selectItemsButton
            deleteFolderButton
        }

        // MARK: Delete Folder Confirmation
        .withConfirmation(
            deleteFolderConfig,
            isPresented: $showDeleteConfirmation
        )
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
                showDeleteConfirmation = true
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
