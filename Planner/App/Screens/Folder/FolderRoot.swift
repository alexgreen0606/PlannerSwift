//
//  FolderRoot.swift
//  Planner
//
//  Created by Alex Green on 12/14/25.
//

import SwiftData
import SwiftUI

struct FolderRootView: View {
    let folder: ChecklistItem
    let sortedItems: [ChecklistItem]
    let rootFolder: ChecklistItem
    let namespace: Namespace.ID
    let openItem: (ChecklistItem, ChecklistItem) -> Void

    @StateObject private var itemSelectEngine = ListEngine<ChecklistItem>()

    @State private var showEditSheet = false
    @State private var showTransferSheet = false
    @State private var showNewItemSheet = false

    /// Considers the selected items and whether any other folder exist to house them.
    @State private var canTransferSelectedItems: Bool = false

    // MARK: - Body

    var body: some View {
        ScrollViewReader { scrollProxy in
            FolderContentsListView(
                folder: folder,
                sortedItems: sortedItems,
                namespace: namespace,
                openItem: openItem
            )
            .overlay {
                if folder.safeItems.isEmpty {
                    EmptyLabel("No items")
                }
            }
            .toolbar {
                topLeadingToolbar
                topTrailingToolbar
            }
            .animateSynchronousAction(from: itemSelectEngine.isSelectMode)
            .navigationTitle(folder.title)
            .navigationBarBackButtonHidden(true)

            // MARK: Scroll to new items.
            .onChange(of: sortedItems) { oldItems, newItems in
                scrollProxy.scrollToNewItem(
                    oldItems: oldItems,
                    newItems: newItems,
                    getId: { $0.stableId }
                )
            }
        }

        // MARK: Transfer Checklist Items Form
        .sheet(isPresented: $showTransferSheet) {
            TransferChecklistItemsFormView(
                source: folder,
                selectedIds: itemSelectEngine.selectedItemIds,
                rootFolder: rootFolder,
                openItem: openItem
            )
            .navigationTransition(
                .zoom(
                    sourceID: ListIds.TRANSFER_BUTTON,
                    in: namespace
                )
            )
        }
        .environmentObject(itemSelectEngine)

        // MARK: Edit Form
        .sheet(isPresented: $showEditSheet) {
            ChecklistItemFormView(item: folder, parent: folder.parent)
        }

        // MARK: New Item Form
        .sheet(isPresented: $showNewItemSheet) {
            ChecklistItemFormView(parent: folder)
        }

        // MARK: Update transferability when selected items change.
        .onChange(of: itemSelectEngine.selectedItemIds) { _, _ in
            updateTransferability()
        }
    }

    // MARK: - Toolbars

    @ToolbarContentBuilder
    private var topLeadingToolbar: some ToolbarContent {
        if !itemSelectEngine.isSelectMode {
            if folder.parent != nil {
                ToolbarItemGroup(placement: .topBarLeading) {
                    BackButtonView()
                }
            }
        } else {
            ToolbarItem(placement: .topBarLeading) {
                CancelButtonView(cancel: itemSelectEngine.toggleSelectMode)
            }
            ToolbarSpacer(.fixed, placement: .topBarLeading)
            ToolbarItem(placement: .topBarLeading) {
                SelectAllToggleView(visibleItems: sortedItems)
            }
        }
    }

    @ToolbarContentBuilder
    private var topTrailingToolbar: some ToolbarContent {
        if !itemSelectEngine.isSelectMode {
            ToolbarItemGroup(placement: .topBarTrailing) {
                FolderActionMenuView(
                    showEditSheet: $showEditSheet,
                    folder: folder,
                    items: sortedItems
                )

                Button("Add", systemImage: "plus") {
                    showNewItemSheet = true
                }
            }
        } else {
            SelectedChecklistItemActionsView(
                showTransferSheet: $showTransferSheet,
                canTransferItems: canTransferSelectedItems,
                parentType: .folder,
                namespace: namespace
            )
        }
    }

    // MARK: - Functions

    private func updateTransferability() {
        canTransferSelectedItems =
            rootFolder.hasChildType(
                .folder,
                excluding: itemSelectEngine.selectedItemIds.union([
                    folder.stableId
                ]
                )
            ) == true
    }
}
