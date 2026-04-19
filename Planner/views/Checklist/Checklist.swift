//
//  Checklist.swift
//  Planner
//
//  Created by Alex Green on 12/14/25.
//

import SwiftData
import SwiftUI

// Clean

struct ChecklistView: View {
    let checklist: ChecklistItem
    let sortedItems: [ChecklistItem]
    let canTransferItems: Bool
    let openItem: (ChecklistItem, ChecklistItem) -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var listManager: ListManager<ChecklistItem>

    @StateObject private var notificationManager = NotificationManager()
    @State private var showEditSheet = false
    @State private var showTransferSheet = false

    @Namespace private var namespace

    private var sortedUncheckedItems: [ChecklistItem] {
        sortedItems
            .filter(listManager.isItemInUncheckedList)
    }

    private var sortedCheckedItems: [ChecklistItem] {
        sortedItems
            .filter(listManager.isItemInCheckedList)
    }

    // Used for the "Select All" button.
    private var visibleItems: [ChecklistItem] {
        if checklist.showCompleted {
            return sortedUncheckedItems + sortedCheckedItems
        }
        return sortedUncheckedItems
    }

    private var isAllSelected: Bool {
        listManager.selectedItemIds.count == visibleItems.count
            && !visibleItems.isEmpty
    }

    private var completedItemExists: Bool {
        sortedItems.contains(where: \.isCompleted)
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { scrollProxy in
                SortableListView<
                    ChecklistItem, EmptyView, EmptyView, EmptyView, EmptyView
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
                .navigationSubtitle(checklist.path)
                .toolbar {
                    topLeadingToolbar
                    topTrailingToolbar
                    bottomToolbar(scrollProxy: scrollProxy)
                }
                .animateSynchronousAction(from: listManager.isSelectMode)
            }
        }
        .overlay {
            if !notificationManager.notifications.isEmpty {
                // Note: Must be rendered conditionally within this file.
                // Changes to notifications are sometimes not recognized within the NotificationsView
                // due to overlay restrictions.
                NotificationsView()
                    .transition(
                        .move(edge: .leading).combined(with: .opacity)
                    )
            }
        }

        // Edit Form
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

        // Transfer Items Form
        .sheet(isPresented: $showTransferSheet) {
            TransferChecklistItemsFormView(
                source: checklist,
                selectedIds: listManager.selectedItemIds,
                openItem: openItem
            )
            .navigationTransition(
                .zoom(
                    sourceID: IdConstants.TRANSFER_BUTTON,
                    in: namespace
                )
            )
        }

        .environmentObject(notificationManager)
    }

    // MARK: - Toolbars

    private var topLeadingToolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            if !listManager.isSelectMode {
                dismissButton
            } else {
                cancelSelectModeButton
            }
        }
    }

    @ToolbarContentBuilder
    private var topTrailingToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if !listManager.isSelectMode {
                ChecklistActionMenu(
                    showEditSheet: $showEditSheet,
                    checklist: checklist,
                    completedItemExists: completedItemExists,
                    completedItems: sortedCheckedItems,
                    visibleItems: visibleItems
                )
            } else {
                toggleSelectAllButton
            }
        }
    }

    @ToolbarContentBuilder
    private func bottomToolbar(
        scrollProxy: ScrollViewProxy
    ) -> some ToolbarContent {
        if !listManager.isSelectMode {
            ToolbarSpacer(placement: .bottomBar)
            ToolbarItem(placement: .bottomBar) {
                createLowerItemButton(scrollProxy: scrollProxy)
            }
        } else {
            SelectedChecklistItemActionsView(
                showTransferSheet: $showTransferSheet,
                canTransferItems: canTransferItems,
                parentType: .checklist,
                namespace: namespace
            )
        }
    }

    // MARK: Top Leading Toolbar Components

    private var dismissButton: some View {
        Button(
            "Back",
            systemImage: "chevron.left",
        ) {
            dismiss()
        }
    }

    private var cancelSelectModeButton: some View {
        Button(
            "Cancel",
            systemImage: "xmark",
            action: listManager.toggleSelectMode
        )
    }

    // MARK: Top Trailing Toolbar Components

    private var toggleSelectAllButton: some View {
        Button {
            listManager.toggleSelectAll(visibleItems: visibleItems)
        } label: {
            Text(isAllSelected ? "Deselect All" : "Select All")
                .fontWeight(.semibold)
        }
        .disabled(visibleItems.isEmpty)
        .animateSynchronousAction(from: isAllSelected)
    }

    // MARK: Bottom Trailing Toolbar Components

    private func createLowerItemButton(scrollProxy: ScrollViewProxy)
        -> some View
    {
        Button("Add", systemImage: "plus") {
            createLowerItem(scrollProxy: scrollProxy)
        }
        .buttonStyle(.glassProminent)
        .tint(checklist.color.swiftUIColor)
    }

    // MARK: - Functions

    private func createItem(at index: Int) {
        listManager.pendingFocusId = modelContext.createChecklistItem(
            at: index,
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
                    IdConstants.UNCHECKED_ITEMS,
                    anchor: .bottom
                )
            }
        }
    }

}
