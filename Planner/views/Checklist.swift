//
//  ChecklistView.swift
//  Planner
//
//  Created by Alex Green on 12/14/25.
//

import SwiftData
import SwiftUI

struct ChecklistView: View {
    private let checklistId: PersistentIdentifier
    private let canTransferItems: Bool
    
    // Can pass a folder to navigate into (passes itself when it is transformed into a folder).
    private let closeChecklist: (ChecklistItem?) -> Void
    
    init(
        checklistId: PersistentIdentifier,
        canTransferItems: Bool,
        closeChecklist: @escaping (ChecklistItem?) -> Void
    ) {
        self.checklistId = checklistId
        self.closeChecklist = closeChecklist
        self.canTransferItems = canTransferItems

        _checklists = Query(
            filter: #Predicate<ChecklistItem> {
                $0.id == checklistId
            }
        )
    }

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var listManager: ListManager<ChecklistItem>
    
    @Query private var checklists: [ChecklistItem]

    @State private var showDeleteCompletedConfirm = false
    @State private var showDeleteChecklistConfirm = false
    @State private var isTransferSheetOpen = false
    @State private var isEditFormOpen = false

    @Namespace private var namespace

    private var checklist: ChecklistItem? {
        checklists.first
    }

    private var hasCheckedItems: Bool {
        checklist?.items.contains(where: \.isChecked) ?? false
    }

    private var sortedUncheckedItems: [ChecklistItem] {
        checklist?.items
            .filter {
                (!$0.isChecked
                    && !listManager.newlyUncheckedIds.contains($0.id))
                    || listManager.newlyCheckedIds.contains($0.id)
            }
            .sorted { $0.sortIndex < $1.sortIndex } ?? []
    }

    private var sortedCheckedItems: [ChecklistItem] {
        checklist?.items
            .filter {
                ($0.isChecked
                    && !listManager.newlyCheckedIds.contains($0.id))
                    || listManager.newlyUncheckedIds.contains($0.id)
            }
            .sorted { $0.sortIndex < $1.sortIndex } ?? []
    }

    private var visibleItems: [ChecklistItem] {
        var allVisibleItems = sortedUncheckedItems

        if checklist?.showCompleted == true {
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

        return checklist?.path ?? ""
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                SortableListView(
                    uncheckedItems: sortedUncheckedItems,
                    checkedItems: sortedCheckedItems,
                    showChecked: checklist?.showCompleted == true,
                    floatingInfo: EmptyView(),
                    customToggleConfig: nil,
                    checkedHeader: "Completed items",
                    checkedFooter: nil,
                    emptyUncheckedLabel: "No items",
                    emptyCheckedLabel: "No completed items",
                    namespace: nil,
                    tint: { _ in checklist?.color.swiftUIColor ?? .blue },
                    toolbarIcons: [],
                    tapToolbar: { _, _ in },
                    leftAdornment: { _ in EmptyView() },
                    rightAdornment: { _ in EmptyView() },
                    bottomAdornment: { _ in EmptyView() },
                    proxy: proxy,
                    createItem: createItem,
                    handleTitleChange: { _ in },
                    moveItem: moveItem,
                    isItemChecked: nil
                )
                .accentColor(checklist?.color.swiftUIColor ?? .blue)
                .navigationTitle(checklist?.title ?? "")
                .navigationSubtitle(subtitle)
                .toolbar {
                    topLeftToolbar
                    topRightToolbar
                    bottomToolbar(proxy)
                }
                .animateSynchronousAction(from: listManager.isSelectMode)
            }
        }

        // Edit Form
        .sheet(isPresented: $isEditFormOpen) {
            if let checklist, let parent = checklist.parent {
                ChecklistItemFormView(item: checklist, parent: parent) {
                    savedList in
                    if savedList.type == .folder {
                        closeChecklist(savedList)
                    }
                }
                .navigationTransition(
                    .zoom(sourceID: "ELLIPSIS", in: namespace)
                )
            }
        }

        // Transfer Form
        .sheet(isPresented: $isTransferSheetOpen) {
            if let checklist {
                TransferChecklistItemsFormView(
                    source: checklist,
                    selectedIds: listManager.selectedItemIds
                )
                .navigationTransition(
                    .zoom(
                        sourceID: "TRANSFER",
                        in: namespace
                    )
                )
            }
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
                Button("Cancel", systemImage: "xmark") {
                    withAnimation {
                        listManager.toggleSelectMode()
                    }
                }
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
                        withAnimation {
                            listManager.toggleSelectMode()
                        }
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
                    id: "ELLIPSIS",
                    in: namespace
                )
                .confirmationDialog(
                    checklist?.deleteConfirmation ?? "",
                    isPresented: $showDeleteChecklistConfirm,
                    titleVisibility: .visible
                ) {
                    Button("Confirm", role: .destructive) {
                        deleteEntireList()
                    }
                } message: {
                    Text(
                        checklist?.deleteWarning ?? ""
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
                    if isAllSelected {
                        listManager.selectedItemIds = []
                        listManager.selectedItems = []
                    } else {
                        listManager.selectedItems = visibleItems
                        listManager.selectedItemIds = Set(
                            visibleItems.map { $0.id }
                        )
                    }
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
        _ proxy: ScrollViewProxy
    ) -> some ToolbarContent {
        ToolbarItemGroup(placement: .bottomBar) {
            if !listManager.isSelectMode {
                Spacer()

                Button("Add", systemImage: "plus") {
                    createItem(at: sortedUncheckedItems.count)

                    DispatchQueue.main.async {
                        withAnimation {
                            proxy.scrollTo(
                                "UNCHECKED",
                                anchor: .top
                            )
                        }
                    }
                }
                .tint(checklist?.color.swiftUIColor ?? .blue)
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
                    id: "TRANSFER",
                    in: namespace
                )
            }
        }
    }

    private var showCompletedToggle: some View {
        Button {
            checklist?.showCompleted.toggle()
        } label: {
            Image(
                systemName: checklist?.showCompleted
                    == true
                    ? "eye.slash" : "eye"
            )
            Text(
                checklist?.showCompleted == true
                    ? "Hide completed"
                    : "Show completed"
            )
        }
    }

    // MARK: - Helper Functions

    private func createItem(
        near baseId: PersistentIdentifier?,
        offset: Int = 0
    ) {
        guard
            let baseIndex = sortedUncheckedItems.firstIndex(where: {
                $0.id == baseId
            })
        else {
            return
        }

        let finalIndex = baseIndex + offset

        // Don't create the new item if it is next to an empty item.
        let upperEvent =
            finalIndex > 0 ? sortedUncheckedItems[finalIndex - 1] : nil
        let lowerEvent =
            finalIndex < sortedUncheckedItems.count
            ? sortedUncheckedItems[finalIndex] : nil
        if let upper = upperEvent, upper.title.isEmpty {
            return
        }
        if let lower = lowerEvent, lower.title.isEmpty {
            return
        }

        createItem(at: finalIndex)
    }

    private func createItem(at index: Int) {
        let sortIndex = generateSortIndex(
            index: index,
            items: sortedUncheckedItems
        )
        let newItem = ChecklistItem(sortIndex: sortIndex, parent: checklist)

        modelContext.insert(newItem)
        try! modelContext.save()
    }

    private func moveItem(from: Int, to: Int) {
        guard from != to else { return }

        let movedEvent = sortedUncheckedItems[from]
        let remainingItems = sortedUncheckedItems.filter {
            $0.id != movedEvent.id
        }
        movedEvent.sortIndex = generateSortIndex(
            index: to,
            items: remainingItems
        )

        try! modelContext.save()
    }

    private func deleteAllCompletedItems() {
        modelContext.deleteChecklistItems(sortedCheckedItems)
    }

    private func deleteEntireList() {
        guard let checklist else {
            return
        }

        closeChecklist(nil)

        modelContext.delete(checklist)

        do {
            try modelContext.save()
        } catch {
            assertionFailure(
                "Failed to delete list: \(error)"
            )
        }
    }

}
