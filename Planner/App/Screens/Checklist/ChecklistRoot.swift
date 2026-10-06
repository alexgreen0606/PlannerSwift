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
    private let settings: Settings
    private let openItem: (ChecklistItem, ChecklistItem) -> Void

    init(
        checklist: ChecklistItem,
        sortedItems: [ChecklistItem],
        rootFolder: ChecklistItem,
        settings: Settings,
        openItem: @escaping (ChecklistItem, ChecklistItem) -> Void
    ) {
        self.checklist = checklist
        self.sortedItems = sortedItems
        self.rootFolder = rootFolder
        self.settings = settings
        self.openItem = openItem

        canTransferSelectedItems = rootFolder.containsType(
            .checklist,
            excluding: Set([checklist.stableId])
        )

        self._listEngine = StateObject(
            wrappedValue: ListEngine<ChecklistItem>(
                toggleState: ListItemToggleState(
                    isToggled: { $0.isCompleted },
                    setIsToggled: { $0.isCompleted = $1 }
                ),
                settings: settings
            )
        )
    }

    private let canTransferSelectedItems: Bool

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @StateObject private var listEngine: ListEngine<ChecklistItem>

    @State private var itemSheetContext: ChecklistItemSheetContext?
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
                        pendingHeader: valueSpread(completed: false),
                        completedHeader: valueSpread(completed: true),
                        createItem: createItem,
                        moveItem: moveItem,
                        onCommitItem: handleItemChange,
                        onAdornmentClick: openItem,
                        sortedPendingItems: sortedPendingItems,
                        sortedCompletedItems: sortedCompletedItems,
                        showCompleted: checklist.showCompleted,
                        tint: { _ in checklist.color.swiftUIColor },
                        leftAdornment: { _ in EmptyView() },
                        rightAdornment: valueAdornment,
                        bottomAdornment: { _ in EmptyView() },
                        scrollProxy: scrollProxy,
                        namespace: namespace,
                        settings: settings
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

            // MARK: Edit Item Form

            .sheet(item: $itemSheetContext) { context in
                ChecklistItemFormView(
                    sourceItem: context.checklistItem
                )
                .navigationTransition(
                    .zoom(
                        sourceID: context.id,
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

    // MARK: - View Builder

    private func valueSpread(completed: Bool) -> some View {
        ChecklistItemFloatingInfoView(
            item: checklist,
            completed: completed
        )
    }

    private func actionToolbar(scrollProxy: ScrollViewProxy) -> some View {
        ListActionToolbarView<
            ChecklistItem,
            SelectedItemActionsView
        >(
            accentColor: checklist.color.swiftUIColor,
            keyboardAccessory: ListKeyboardAccessoryView(
                iconImageNames: ["info"],
                onIconTap: openFocusedItem
            ),
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

    @ViewBuilder
    private func valueAdornment(item: ChecklistItem) -> some View {
        if !item.value.isZero {
            ChecklistItemValueView(value: item.sum(completed: item.isCompleted))
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

    private func openFocusedItem(_: String) {
        if let focusedItem = listEngine.activeEditor?.item {
            openItem(focusedItem)
        }
    }

    private func openItem(_ item: ChecklistItem) {
        listEngine.openSheet(for: item) {
            itemSheetContext = ChecklistItemSheetContext(
                checklistItem: item
            )
        }
    }

    private func handleItemChange(item: ChecklistItem, _: ChecklistItem) {
        modelContext.handleChecklistItemChange(item: item)
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
