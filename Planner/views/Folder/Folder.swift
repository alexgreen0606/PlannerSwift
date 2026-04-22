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

    @StateObject private var selectManager = ListManager<ChecklistItem>()
    @State private var showTransferSheet = false
    @State private var showCreateSheet = false
    @State private var showEditSheet = false

    var sortedItems: [ChecklistItem] {
        folder.safeItems.sorted { $0.sortIndex < $1.sortIndex }
    }

    var isAllSelected: Bool {
        selectManager.selectedItemIds.count == sortedItems.count
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
            if folder.safeItems.isEmpty {
                EmptyLabelView("No contents")
            }
        }
        .environmentObject(selectManager)
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
                FolderActionMenuView(
                    showEditSheet: $showEditSheet,
                    folder: folder,
                    sortedItems: sortedItems
                )

                Button("Add", systemImage: "plus") {
                    showCreateSheet = true
                }
            }
        } else {
            SelectedChecklistItemActionsView(
                showTransferSheet: $showTransferSheet,
                canTransferItems: canTranferItems,
                parentType: .folder,
                namespace: namespace
            )
        }
    }

    // MARK: - Functions

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
