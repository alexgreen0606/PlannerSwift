//
//  Folder.swift
//  Planner
//
//  Created by Alex Green on 12/14/25.
//

import SwiftData
import SwiftUI

// Clean

struct FolderView: View {
    let folder: ChecklistItem
    let namespace: Namespace.ID
    let openItem: (ChecklistItem, ChecklistItem) -> Void
    let canTranferItems: Bool
    let updateTransferAvailability: (Set<UUID>) -> Void

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @StateObject private var notificationManager = NotificationManager()
    @StateObject private var selectManager = ListManager<ChecklistItem>()
    @State private var showDeleteFolderConfirm = false
    @State private var showTransferSheet = false
    @State private var showCreateSheet = false
    @State private var showEditSheet = false

    var sortedItems: [ChecklistItem] {
        folder.items.sorted { $0.sortIndex < $1.sortIndex }
    }

    var isAllSelected: Bool {
        selectManager.selectedItemIds.count == sortedItems.count
    }

    private var navigationSubtitle: String {
        if selectManager.isSelectMode {
            let count = selectManager.selectedItems.count
            return
                "\(count == 0 ? "No" : String(count)) items selected"
        }

        return folder.path
    }

    var body: some View {
        ScrollViewReader { scrollProxy in
            FolderContentsListView(
                folder: folder,
                sortedItems: sortedItems,
                namespace: namespace,
                openItem: openItem,
                updateTransferAvailability: updateTransferAvailability
            )
            .navigationTitle(folder.title)
            .navigationSubtitle(navigationSubtitle)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                topLeftToolbar
                topRightToolbar
            }
            .animateSynchronousAction(from: selectManager.isSelectMode)

            // Create Item Form
            .sheet(isPresented: $showCreateSheet) {
                ChecklistItemFormView(parent: folder) { newItemId in
                    scrollTo(id: newItemId, scrollProxy: scrollProxy)
                }
            }

            // Edit Form
            .sheet(isPresented: $showEditSheet) {
                ChecklistItemFormView(item: folder, parent: folder.parent)
            }

            // Transfer Items Form
            .sheet(isPresented: $showTransferSheet) {
                TransferChecklistItemsFormView(
                    source: folder,
                    selectedIds: selectManager.selectedItemIds,
                    openItem: openItem
                )
                .navigationTransition(
                    .zoom(
                        sourceID: IdConstants.TRANSFER_BUTTON,
                        in: namespace
                    )
                )
            }
        }
        .overlay {
            if folder.items.isEmpty {
                EmptyLabelView("No contents")
            }
        }
        .overlay {
            NotificationsView()
        }
        .environmentObject(selectManager)
        .environmentObject(notificationManager)
    }

    // MARK: - Toolbars

    @ToolbarContentBuilder
    private var topLeftToolbar: some ToolbarContent {
        if !selectManager.isSelectMode {
            if folder.parent != nil {
                ToolbarItemGroup(placement: .topBarLeading) {
                    Button("Back", systemImage: "chevron.left") {
                        dismiss()
                    }
                }
            }
        } else {
            ToolbarItem(placement: .topBarLeading) {
                Button(
                    "Close",
                    systemImage: "xmark",
                    action: selectManager.toggleSelectMode
                )
            }

            ToolbarSpacer(.fixed, placement: .topBarLeading)

            ToolbarItem(placement: .topBarLeading) {
                Button {
                    selectManager.toggleSelectAll(visibleItems: sortedItems)
                } label: {
                    Text(isAllSelected ? "Deselect All" : "Select All")
                        .fontWeight(.semibold)
                }
                .disabled(sortedItems.isEmpty)
            }
        }
    }

    @ToolbarContentBuilder
    private var topRightToolbar: some ToolbarContent {
        if !selectManager.isSelectMode {
            ToolbarItemGroup(placement: .topBarTrailing) {
                actionMenu
                addNewItemButton
            }
        } else {
            selectedModeActionButtons
        }
    }

    // MARK: Action Menu

    @ViewBuilder
    private var actionMenu: some View {
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

    private var editFolderButton: some View {
        Button {
            showEditSheet = true
        } label: {
            Label("Edit folder", systemImage: "pencil")
        }
    }

    private var selectItemsButton: some View {
        Button {
            selectManager.toggleSelectMode()
        } label: {
            Label("Select contents", systemImage: "checkmark.circle")
        }
        .disabled(sortedItems.isEmpty)
    }

    @ViewBuilder
    private var deleteFolderButton: some View {
        if folder.parent != nil {
            Button(role: .destructive) {
                showDeleteFolderConfirm = true
            } label: {
                Label("Delete this folder", systemImage: "trash")
            }
        }
    }

    // MARK: Add New Item Button

    @ViewBuilder
    private var addNewItemButton: some View {
        Button("Add", systemImage: "plus") {
            showCreateSheet = true
        }
    }

    // MARK: Select Mode Actions

    @ToolbarContentBuilder
    private var selectedModeActionButtons: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            DeleteSelectedButtonView(
                itemsLabel: "contents",
                disabled: selectManager.selectedItemIds.isEmpty,
                delete: deleteSelectedItems
            )
        }

        ToolbarSpacer(.fixed, placement: .topBarTrailing)

        ToolbarItem(placement: .topBarTrailing) {
            transferItemsButton
        }
    }

    private var transferItemsButton: some View {
        Button(
            "Transfer",
            systemImage: "arrow.forward.folder"
        ) {
            showTransferSheet = true
        }
        .matchedTransitionSource(
            id: IdConstants.TRANSFER_BUTTON,
            in: namespace
        )
        .disabled(
            !canTranferItems || selectManager.selectedItemIds.isEmpty
        )
    }

    // MARK: - Functions

    private func deleteEntireFolder() {
        dismiss()
        modelContext.safeDelete(folder)
    }

    private func deleteSelectedItems() {
        withAnimation {
            modelContext.deleteChecklistItems(
                selectManager.selectedItems
            )
        }

        DispatchQueue.main.async {
            selectManager.toggleSelectMode()
        }
    }

    private func scrollTo(id: UUID?, scrollProxy: ScrollViewProxy) {
        guard let targetId = id else { return }

        DispatchQueue.main.async {
            withAnimation {
                scrollProxy.scrollTo(
                    targetId,
                    anchor: .bottom
                )
            }
        }
    }

}
