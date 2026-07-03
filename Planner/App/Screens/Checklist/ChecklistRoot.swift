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

        canTransferSelectedItems = rootFolder.containsType(
            .checklist,
            excluding: Set([checklist.stableId])
        )
    }

    private let canTransferSelectedItems: Bool

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @StateObject private var listEngine = ListEngine<ChecklistItem>(
        toggleState: ListItemToggleState(
            isToggled: { $0.isCompleted },
            setIsToggled: { $0.isCompleted = $1 }
        )
    )

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
                    .safeAreaBar(edge: .bottom) {
                        actionToolbar(scrollProxy: scrollProxy)
                    }
                    .toolbar {
                        topLeadingToolbar

                        ChecklistItemHeaderView(item: checklist)

                        topTrailingToolbar
                    }
                    .navigationBarTitleDisplayMode(.inline)
                }
            }

            // MARK: Transfer Selected Items Form

            .sheet(isPresented: $showTransferSheet) {
                TransferChecklistItemsFormView(
                    sourceItem: checklist,
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
            .environmentObject(listEngine)

            // MARK: Edit Checklist Form

            .sheet(isPresented: $showEditSheet) {
                ChecklistItemFormView(
                    sourceItem: checklist,
                    onDelete: {
                        dismiss()
                    }
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

    // MARK: - View Builder

    private func actionToolbar(scrollProxy: ScrollViewProxy) -> some View {
        ListActionToolbarView<
            ChecklistItem,
            SelectedItemActionsView
        >(
            accentColor: checklist.color.swiftUIColor,
            selectedItemActions: SelectedItemActionsView(
                showTransferSheet: $showTransferSheet,
                canTransferItems: canTransferSelectedItems,
                namespace: namespace
            ),
            createItem: {
                createLowerItem(scrollProxy: scrollProxy)
            }
        )
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
            initialIndex: from,
            targetIndex: to,
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
