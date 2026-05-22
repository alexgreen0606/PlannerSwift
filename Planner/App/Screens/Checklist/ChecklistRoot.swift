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
    private let rootFolder: ChecklistItem
    private let sortedPendingItems: [ChecklistItem]
    private let sortedCheckedItems: [ChecklistItem]
    private let openItem: (ChecklistItem, ChecklistItem) -> Void

    init(
        checklist: ChecklistItem,
        rootFolder: ChecklistItem,
        sortedPendingItems: [ChecklistItem],
        sortedCheckedItems: [ChecklistItem],
        openItem: @escaping (ChecklistItem, ChecklistItem) -> Void
    ) {
        self.checklist = checklist
        self.rootFolder = rootFolder
        self.sortedPendingItems = sortedPendingItems
        self.sortedCheckedItems = sortedCheckedItems
        self.openItem = openItem

        self.canTransferSelectedItems =
            rootFolder.hasChildType(
                .checklist,
                excluding: Set([checklist.stableId])
            )
            == true
    }

    private let canTransferSelectedItems: Bool

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var listEngine: ListEngine<ChecklistItem>

    @State private var showEditSheet = false
    @State private var showTransferSheet = false

    @Namespace private var namespace

    private var allItems: [ChecklistItem] {
        sortedPendingItems + sortedCheckedItems
    }

    private var visibleItems: [ChecklistItem] {
        if checklist.showCompleted {
            return allItems
        }
        return sortedPendingItems
    }

    // MARK: - Body

    var body: some View {
        ToastRootView(listEngine: listEngine) {
            NavigationStack {
                ScrollViewReader { scrollProxy in
                    SortableListView<
                        ChecklistItem, EmptyView, EmptyView, EmptyView,
                        EmptyView
                    >(
                        uncheckedItems: sortedPendingItems,
                        checkedItems: sortedCheckedItems,
                        showChecked: checklist.showCompleted,
                        checkedHeader: "Completed items",
                        emptyUncheckedLabel: "No items",
                        emptyCheckedLabel: "No completed items",
                        tint: { _ in checklist.color.swiftUIColor },
                        scrollProxy: scrollProxy,
                        createItem: createItem,
                        moveItem: moveItem
                    )
                    .toolbar {
                        topLeadingToolbar
                        topTrailingToolbar
                        bottomToolbar(scrollProxy: scrollProxy)
                    }
                    .animateSynchronousAction(from: listEngine.isSelectMode)
                    .navigationTitle(checklist.title)
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
        ToolbarItem(placement: .cancellationAction) {
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
                ChecklistActionMenu(
                    showEditSheet: $showEditSheet,
                    checklist: checklist,
                    items: allItems,
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
            // TODO: cant 2 items have the same sort ID (one unchecked, one checked) DESIGN FLAW
            in: sortedPendingItems,
            parent: checklist
        )
    }

    private func moveItem(from: Int, to: Int) {
        modelContext.moveChecklistItem(
            in: sortedPendingItems,
            from: from,
            to: to
        )
    }

    private func createLowerItem(scrollProxy: ScrollViewProxy) {
        createItem(at: sortedPendingItems.count)
        scrollProxy.scrollToListBottom()
    }
    
}
