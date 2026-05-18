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
    private let sortedItems: [ChecklistItem]
    private let openItem: (ChecklistItem, ChecklistItem) -> Void

    init(
        checklist: ChecklistItem,
        rootFolder: ChecklistItem,
        sortedItems: [ChecklistItem],
        openItem: @escaping (ChecklistItem, ChecklistItem) -> Void
    ) {
        self.checklist = checklist
        self.rootFolder = rootFolder
        self.sortedItems = sortedItems
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

    private var sortedUncheckedItems: [ChecklistItem] {
        sortedItems
            .filter(listEngine.isItemInUncheckedList)
    }

    private var sortedCheckedItems: [ChecklistItem] {
        sortedItems
            .filter(listEngine.isItemInCheckedList)
    }

    private var visibleItems: [ChecklistItem] {
        if checklist.showCompleted {
            return sortedUncheckedItems + sortedCheckedItems
        }
        return sortedUncheckedItems
    }

    private var isAllSelected: Bool {
        !visibleItems.isEmpty
            && listEngine.selectedItemIds.count == visibleItems.count
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
                        uncheckedItems: sortedUncheckedItems,
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
                    .navigationTitle(checklist.title)
                    .toolbar {
                        topLeadingToolbar
                        topTrailingToolbar
                        bottomToolbar(scrollProxy: scrollProxy)
                    }
                    .animateSynchronousAction(from: listEngine.isSelectMode)
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

    // MARK: Top Leading Toolbar

    private var topLeadingToolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            if !listEngine.isSelectMode {
                dismissButton
            } else {
                cancelSelectModeButton
            }
        }
    }

    private var dismissButton: some View {
        Button(
            "Back",
            systemImage: "chevron.left"
        ) {
            dismiss()
        }
        .tint(Color.label)
    }

    private var cancelSelectModeButton: some View {
        Button(
            "Cancel Select Mode",
            systemImage: "xmark",
            action: listEngine.toggleSelectMode
        )
        .tint(Color.label)
    }

    // MARK: Top Trailing Toolbar

    @ToolbarContentBuilder
    private var topTrailingToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if !listEngine.isSelectMode {
                ChecklistActionMenu(
                    showEditSheet: $showEditSheet,
                    checklist: checklist,
                    items: sortedItems,
                    visibleItems: visibleItems
                )
            } else {
                toggleSelectAllButton
            }
        }
    }

    private var toggleSelectAllButton: some View {
        Button {
            listEngine.toggleSelectAll(visibleItems: visibleItems)
        } label: {
            Text(isAllSelected ? "Deselect All" : "Select All")
                .fontWeight(.semibold)
        }
        .disabled(visibleItems.isEmpty)
        .animateSynchronousAction(from: isAllSelected)
    }

    // MARK: Bottom Trailing Toolbar Components

    @ToolbarContentBuilder
    private func bottomToolbar(
        scrollProxy: ScrollViewProxy
    ) -> some ToolbarContent {
        if !listEngine.isSelectMode {
            ToolbarSpacer(placement: .bottomBar)
            ToolbarItem(placement: .bottomBar) {
                createLowerItemButton(scrollProxy: scrollProxy)
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

    private func createLowerItemButton(scrollProxy: ScrollViewProxy)
        -> some View
    {
        Button("Create Item", systemImage: "plus") {
            createLowerItem(scrollProxy: scrollProxy)
        }
        .buttonStyle(.glassProminent)
        .tint(checklist.color.swiftUIColor)
    }

    // MARK: - Functions

    private func createItem(at index: Int) {
        listEngine.pendingFocusId = modelContext.createChecklistItem(
            at: index,
            // TODO: cant 2 items have the same sort ID (one unchecked, one checked) DESIGN FLAW
            in: sortedUncheckedItems,
            parent: checklist
        )
    }

    private func moveItem(from: Int, to: Int) {
        modelContext.moveChecklistItem(
            in: sortedUncheckedItems,
            from: from,
            to: to
        )
    }

    private func createLowerItem(scrollProxy: ScrollViewProxy) {
        createItem(at: sortedUncheckedItems.count)
        scrollToBottom(scrollProxy: scrollProxy)
    }

    private func scrollToBottom(scrollProxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            withAnimation {
                scrollProxy.scrollTo(
                    ListIds.UNCHECKED_ITEMS,
                    anchor: .bottom
                )
            }
        }
    }
}
