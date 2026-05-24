//
//  FolderActionMenu.swift
//  Planner
//
//  Created by Alex Green on 4/16/26.
//

import SwiftData
import SwiftUI

struct FolderActionMenuView: View {
    @Binding var showEditSheet: Bool
    let folder: ChecklistItem
    let items: [ChecklistItem]

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var showDeleteConfirmation = false

    private var deleteFolderConfig: ConfirmationConfig {
        deleteChecklistItemConfig(
            item: folder,
            delete: deleteFolder
        )
    }

    // MARK: - Body

    var body: some View {
        Menu("", systemImage: "ellipsis") {
            SelectItemsButtonView<ChecklistItem>(hasVisibleItem: !items.isEmpty)
            editFolderButton
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

    private func deleteFolder() {
        DispatchQueue.main.async {
            dismiss()

            DispatchQueue.main.async {
                modelContext.safeDelete(folder)
            }
        }
    }
}
