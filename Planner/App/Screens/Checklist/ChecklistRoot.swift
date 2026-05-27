//
//  ChecklistRoot.swift
//  Planner
//
//  Created by Alex Green on 12/14/25.
//

import SwiftData
import SwiftUI

struct ChecklistRootView: View {
    private let checklist: ChecklistItem
    private let sortedItems: [ChecklistItem]
    private let rootFolder: ChecklistItem
    private let openItem: (ChecklistItem, ChecklistItem) -> Void

    init(
        checklist: ChecklistItem,
        sortedItems: [ChecklistItem],
        rootFolder: ChecklistItem,
        openItem: @escaping (ChecklistItem, ChecklistItem) -> Void
    ) {
        self.checklist = checklist
        self.sortedItems = sortedItems
        self.rootFolder = rootFolder
        self.openItem = openItem

        canTransferSelectedItems =
            rootFolder.hasChildType(
                .checklist,
                excluding: Set([checklist.stableId])
            )
            == true
    }

    private let canTransferSelectedItems: Bool

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var listEngine = ListEngine<ChecklistItem>()

    @State private var showEditSheet = false
    @State private var showTransferSheet = false

    @Namespace private var namespace
    
    private var sortedPendingItems: [ChecklistItem] {
        sortedItems.filter {
            listEngine.isItemInPendingList($0)
        }
    }

    private var sortedCompletedItems: [ChecklistItem] {
        sortedItems.filter {
            listEngine.isItemInCompletedList($0)
        }
    }
    
    private var visibleItems: [ChecklistItem] {
        if checklist.showCompleted {
            return sortedItems
        }
        return sortedPendingItems
    }

    // MARK: - Body

    var body: some View {
        ToastRootView(listEngine: listEngine) {
            NavigationStack {
                ScrollViewReader { scrollProxy in
                    SortableTextfieldListView(
                        sortedItems: sortedItems,
                        createItem: createItem,
                        moveItem: moveItem,
                        sortedPendingItems: sortedPendingItems,
                        emptyPendingLabel: "No items",
                        sortedCompletedItems: sortedCompletedItems,
                        showCompleted: checklist.showCompleted,
                        completedHeader: "Completed items",
                        emptyCompletedLabel: "No completed items",
                        tint: { _ in checklist.color.swiftUIColor },
                        leftAdornment: { _ in EmptyView() },
                        rightAdornment: { _ in EmptyView() },
                        bottomAdornment: { _ in EmptyView() },
                        scrollProxy: scrollProxy
                    )
                    .toolbar {
                        topLeadingToolbar
                        
                        ChecklistItemHeaderView(item: checklist)
                        
                        topTrailingToolbar
                        bottomToolbar(scrollProxy: scrollProxy)
                    }
                    .navigationBarTitleDisplayMode(.inline)
                }
            }

            // MARK: Edit Checklist Form

            .sheet(isPresented: $showEditSheet) {
                if let parent = checklist.parent {
                    ChecklistItemFormView(
                        item: checklist,
                        parent: parent,
                        onDelete: {
                            dismiss()
                        }
                    )
                }
            }

            // MARK: Transfer Selected Items Form

            .sheet(isPresented: $showTransferSheet) {
                TransferChecklistItemsFormView(
                    source: checklist,
                    selectedIds: listEngine.selectedItemIds,
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
        }
    }

    // MARK: - Toolbars

    private var topLeadingToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if !listEngine.isSelectMode {
                BackButtonView()
            } else {
                CancelButtonView(cancel: listEngine.toggleSelectMode)
            }
        }
    }

    @ToolbarContentBuilder
    private var topTrailingToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if !listEngine.isSelectMode {
                ChecklistActionMenuView(
                    showEditSheet: $showEditSheet,
                    checklist: checklist,
                    items: sortedItems,
                    visibleItems: visibleItems
                )
            } else {
                SelectAllToggleView(visibleItems: visibleItems)
            }
        }
    }

    @ToolbarContentBuilder
    private func bottomToolbar(
        scrollProxy: ScrollViewProxy
    ) -> some ToolbarContent {
        if !listEngine.isSelectMode {
            ToolbarSpacer(placement: .bottomBar)
            ToolbarItem(placement: .bottomBar) {
                CreateLowerItemButtonView(tint: checklist.color.swiftUIColor) {
                    createLowerItem(scrollProxy: scrollProxy)
                }
            }
        } else {
            SelectedChecklistItemActionsView(
                showTransferSheet: $showTransferSheet,
                canTransferItems: canTransferSelectedItems,
                parentType: .checklist,
                namespace: namespace
            )
        }
    }

    // MARK: - Functions

    private func createItem(at index: Int) {
        listEngine.pendingFocusId = modelContext.createChecklistItem(
            at: index,
            in: sortedItems,
            parent: checklist
        )
    }

    private func moveItem(from: Int, to: Int) {
        modelContext.moveChecklistItem(
            from: from,
            to: to,
            sortedPendingItems: sortedPendingItems,
            sortedItems: sortedItems
        )
    }

    private func createLowerItem(scrollProxy: ScrollViewProxy) {
        let targetIndex = getInsertionIndex(
            pendingIndex: sortedPendingItems.count,
            sortedPendingItems: sortedPendingItems,
            sortedItems: sortedItems
        )
        
        createItem(at: targetIndex)
        scrollProxy.scrollToBottomOfList()
    }
}
