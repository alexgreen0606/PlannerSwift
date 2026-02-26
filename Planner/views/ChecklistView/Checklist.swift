//
//  ChecklistView.swift
//  Planner
//
//  Created by Alex Green on 12/14/25.
//

import SwiftData
import SwiftUI

struct ChecklistView: View {
    private let checklist: ChecklistItem
    private let canTransferItems: Bool

    // Can pass a folder to navigate into (passes itself when it is transformed into a folder).
    private let closeChecklist: (ChecklistItem?) -> Void

    init(
        checklist: ChecklistItem,
        canTransferItems: Bool,
        closeChecklist: @escaping (ChecklistItem?) -> Void
    ) {
        self.checklist = checklist
        self.canTransferItems = canTransferItems
        self.closeChecklist = closeChecklist
        let checklistId = checklist.stableId

        // Note: We must query the items separately.
        // Using checklist.items causes each list row to lose its state when a new item is inserted.
        _items = Query(
            filter: #Predicate<ChecklistItem> { item in
                item.parent?.stableId == checklistId
            }
        )
    }

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var listManager: ListManager<ChecklistItem>

    @Query private var items: [ChecklistItem]
    
    @State private var isEditFormOpen = false
    @State private var isTransferSheetOpen = false
    @Namespace private var namespace

    @State private var showDeleteCompletedConfirm = false
    @State private var showDeleteChecklistConfirm = false

    private var hasCheckedItems: Bool {
        items.contains(where: \.isChecked)
    }

    private var sortedUncheckedItems: [ChecklistItem] {
        items
            .filter {
                (!$0.isChecked
                    && !listManager.newlyUncheckedIds.contains($0.stableId))
                    || listManager.newlyCheckedIds.contains($0.stableId)
            }
            .sorted { $0.sortIndex < $1.sortIndex }
    }

    private var sortedCheckedItems: [ChecklistItem] {
        items
            .filter {
                ($0.isChecked
                    && !listManager.newlyCheckedIds.contains($0.stableId))
                    || listManager.newlyUncheckedIds.contains($0.stableId)
            }
            .sorted { $0.sortIndex < $1.sortIndex }
    }

    private var visibleItems: [ChecklistItem] {
        var allVisibleItems = sortedUncheckedItems

        if checklist.showCompleted {
            allVisibleItems.append(
                contentsOf: sortedCheckedItems
            )
        }

        return allVisibleItems
    }

    private var isAllSelected: Bool {
        listManager.selectedItemIds.count == visibleItems.count
            && !visibleItems.isEmpty
    }

    private var subtitle: String {
        if listManager.isSelectMode {
            let count = listManager.selectedItems.count
            return
                "\(count == 0 ? "No" : String(count)) item\(count == 1 ? "" : "s") selected"
        }

        return checklist.path
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { scrollProxy in
                SortableListView(
                    uncheckedItems: sortedUncheckedItems,
                    checkedItems: sortedCheckedItems,
                    showChecked: checklist.showCompleted,
                    floatingInfo: EmptyView(),
                    customToggleConfig: nil,
                    checkedHeader: "Completed items",
                    checkedFooter: nil,
                    emptyUncheckedLabel: "No items",
                    emptyCheckedLabel: "No completed items",
                    namespace: nil,
                    tint: { _ in checklist.color.swiftUIColor },
                    toolbarIcons: [],
                    tapToolbar: { _, _ in },
                    leftAdornment: { _ in EmptyView() },
                    rightAdornment: { _ in EmptyView() },
                    bottomAdornment: { _ in EmptyView() },
                    scrollProxy: scrollProxy,
                    createItem: createItem,
                    handleTitleChange: { _ in },
                    moveItem: moveItem,
                    isItemChecked: nil
                )
                .accentColor(checklist.color.swiftUIColor)
                .navigationTitle(checklist.title)
                .navigationSubtitle(subtitle)
                .toolbar {
                    topLeftToolbar
                    topRightToolbar
                    bottomToolbar(scrollProxy: scrollProxy)
                }
                .animateSynchronousAction(from: listManager.isSelectMode)
            }
        }

        // Edit Form
        .sheet(isPresented: $isEditFormOpen) {
            if let parent = checklist.parent {
                ChecklistItemFormView(item: checklist, parent: parent) {
                    savedList in
                    if savedList.type == .folder {
                        closeChecklist(savedList)
                    }
                }
                .navigationTransition(
                    .zoom(sourceID: IDConstants.ELLIPSIS_BUTTON, in: namespace)
                )
            }
        }

        // Transfer Form
        .sheet(isPresented: $isTransferSheetOpen) {
            TransferChecklistItemsFormView(
                source: checklist,
                selectedIds: listManager.selectedItemIds
            )
            .navigationTransition(
                .zoom(
                    sourceID: IDConstants.TRANSFER_BUTTON,
                    in: namespace
                )
            )
        }
    }

    // MARK: - Helper Views

    private var topLeftToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if !listManager.isSelectMode {
                Button(
                    "Back",
                    systemImage: "chevron.left"
                ) {
                    closeChecklist(nil)
                }
            } else {
                Button(
                    "Cancel",
                    systemImage: "xmark",
                    action: listManager.toggleSelectMode
                )
            }
        }
    }

    @ToolbarContentBuilder
    private var topRightToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            if !listManager.isSelectMode {
                Menu {
                    showCompletedToggle

                    Button {
                        isEditFormOpen = true
                    } label: {
                        Text("Edit checklist details")
                        Image(systemName: "pencil")
                    }

                    Button {
                        listManager.toggleSelectMode()
                    } label: {
                        Image(systemName: "checkmark.circle")
                        Text("Select items")
                            .fontWeight(.semibold)
                    }
                    .disabled(visibleItems.isEmpty)

                    Menu {
                        Button(role: .destructive) {
                            showDeleteCompletedConfirm = true
                        } label: {
                            Text("Delete completed items")
                        }
                        .disabled(!hasCheckedItems)

                        Button(role: .destructive) {
                            showDeleteChecklistConfirm = true
                        } label: {
                            Text("Delete this list")
                        }
                    } label: {
                        Label(
                            "Delete options",
                            systemImage: "trash"
                        )
                    }

                } label: {
                    Image(systemName: "ellipsis")
                }
                .matchedTransitionSource(
                    id: IDConstants.ELLIPSIS_BUTTON,
                    in: namespace
                )
                .confirmationDialog(
                    checklist.deleteConfirmation,
                    isPresented: $showDeleteChecklistConfirm,
                    titleVisibility: .visible
                ) {
                    Button(
                        "Confirm",
                        role: .destructive,
                        action: deleteEntireList
                    )
                } message: {
                    Text(
                        checklist.deleteWarning
                    )
                }
                .confirmationDialog(
                    "Delete completed items from this list?",
                    isPresented: $showDeleteCompletedConfirm,
                    titleVisibility: .visible
                ) {
                    Button("Confirm", role: .destructive) {
                        deleteAllCompletedItems()
                    }
                } message: {
                    Text("This action is irreversible.")
                }
            } else {
                Button {
                    listManager.toggleSelectAll(visibleItems: visibleItems)
                } label: {
                    Text(isAllSelected ? "Deselect All" : "Select All")
                        .fontWeight(.semibold)
                }
                .disabled(visibleItems.isEmpty)
                .animateSynchronousAction(from: isAllSelected)
            }
        }
    }

    @ToolbarContentBuilder
    private func bottomToolbar(
        scrollProxy: ScrollViewProxy
    ) -> some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            if !listManager.isSelectMode {
                Spacer()

                Button("Add", systemImage: "plus") {
                    createLowerItem(scrollProxy: scrollProxy)
                }
                .tint(checklist.color.swiftUIColor)
            } else {
                DeleteSelectedButtonView(
                    itemsLabel: "items",
                    disabled: listManager.selectedItemIds.isEmpty,
                    warningMessage: nil
                ) {
                    modelContext.deleteChecklistItems(
                        listManager.selectedItems
                    )

                    DispatchQueue.main.asyncAfter(
                        deadline: .now() + .milliseconds(750)
                    ) {
                        listManager.toggleSelectMode()
                    }
                }

                Spacer()

                Button(
                    "Transfer",
                    systemImage: "arrow.forward.folder"
                ) {
                    isTransferSheetOpen = true
                }
                .disabled(
                    !canTransferItems || listManager.selectedItemIds.isEmpty
                )
                .matchedTransitionSource(
                    id: IDConstants.TRANSFER_BUTTON,
                    in: namespace
                )
            }
        }
    }

    private var showCompletedToggle: some View {
        Button {
            checklist.showCompleted.toggle()
        } label: {
            Image(
                systemName: checklist.showCompleted
                    ? "eye.slash" : "eye"
            )
            Text(
                checklist.showCompleted
                    ? "Hide completed"
                    : "Show completed"
            )
        }
    }

    // MARK: - Helper Functions

    private func createItem(
        near baseId: UUID?,
        offset: Int
    ) {
        if let newId = modelContext.createChecklistItem(
            in: sortedUncheckedItems,
            near: baseId,
            offset: offset,
            parent: checklist
        ) {
            listManager.pendingFocusId = newId
        }
    }

    private func moveItem(from: Int, to: Int) {
        modelContext.moveChecklistItem(
            in: sortedUncheckedItems,
            from: from,
            to: to
        )
    }

    private func deleteAllCompletedItems() {
        modelContext.deleteChecklistItems(sortedCheckedItems)
    }

    private func deleteEntireList() {
        closeChecklist(nil)
        modelContext.deleteChecklistItem(checklist)
    }

    private func createLowerItem(scrollProxy: ScrollViewProxy) {

        createItem(
            near: sortedUncheckedItems.last?.stableId,
            offset: 1
        )

        DispatchQueue.main.async {
            withAnimation {
                scrollProxy.scrollTo(
                    IDConstants.UNCHECKED_ITEMS,
                    anchor: .bottom
                )
            }
        }

    }

}
