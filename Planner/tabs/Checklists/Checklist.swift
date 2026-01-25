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
    private let closeChecklist: () -> Void

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var listManager: ListManager<ChecklistItem>
    @Query private var checklists: [ChecklistItem]

    @State private var showDeleteCompletedConfirm = false
    @State private var showDeleteChecklistConfirm = false
    @State private var showDeleteSelectedConfirm = false

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
    }

    private var subtitle: String {
        if listManager.isSelectMode {
            let count = listManager.selectedItems.count
            return
                "Select Mode  |  \(count == 0 ? "No" : String(count)) items selected"
        }

        return checklist?.itemPath ?? ""
    }

    init(
        checklistId: PersistentIdentifier,
        closeChecklist: @escaping () -> Void
    ) {
        self.checklistId = checklistId
        self.closeChecklist = closeChecklist

        _checklists = Query(
            filter: #Predicate<ChecklistItem> {
                $0.id == checklistId
            }
        )
    }

    var body: some View {
        NavigationStack {
            ScrollViewReader { proxy in
                SortableListView(
                    uncheckedItems: sortedUncheckedItems,
                    checkedItems: sortedCheckedItems,
                    showChecked: checklist?.showCompleted ?? false,
                    floatingInfo: EmptyView(),
                    customToggleConfig: nil,
                    checkedHeader: "Completed items",
                    checkedFooter: nil,
                    emptyUncheckedLabel: "No items",
                    emptyCheckedLabel: "No completed items",
                    tint: checklist?.color.swiftUIColor ?? .blue,
                    getEndAdornment: { _ in EmptyView() },
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
            }
        }
    }

    // MARK: - Helper Views

    private var topLeftToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarLeading) {
            if !listManager.isSelectMode {
                Button(
                    "Back",
                    systemImage: "arrow.down.right.and.arrow.up.left"
                ) {
                    closeChecklist()
                }
            }
            Button("Cancel", systemImage: "xmark") {
                listManager.exitSelectMode()
            }
        }
    }

    @ToolbarContentBuilder
    private var topRightToolbar: some ToolbarContent {
        if !listManager.isSelectMode {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Select") {
                    listManager.toggleType = .staging
                }
            }

            ToolbarSpacer(.fixed, placement: .topBarTrailing)

            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    showCompletedToggle

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
                .confirmationDialog(
                    "Delete this entire list?",
                    isPresented: $showDeleteChecklistConfirm,
                    titleVisibility: .visible
                ) {
                    Button("Confirm", role: .destructive) {
                        deleteEntireList()
                    }
                } message: {
                    Text(
                        "\(checklist?.items.isEmpty == true ? "" : "All items will be lost. ")This action is irreversible."
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
            }
        } else {
            ToolbarItem(placement: .topBarTrailing) {
                Button(isAllSelected ? "Deselect All" : "Select All") {
                    if isAllSelected {
                        listManager.selectedItemIds = []
                        listManager.selectedItems = []
                    } else {
                        listManager.selectedItems = visibleItems
                        listManager.selectedItemIds = Set(
                            visibleItems.map { $0.id }
                        )
                    }
                }
                .disabled(visibleItems.isEmpty)
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
                    proxy.slideTo(
                        "UNCHECKED",
                        at: .bottom
                    )
                }
            } else {

                Button("Delete", systemImage: "trash") {
                    showDeleteSelectedConfirm = true
                }
                .disabled(listManager.selectedItemIds.isEmpty)
                .confirmationDialog(
                    "Delete selected items?",
                    isPresented: $showDeleteSelectedConfirm,
                    titleVisibility: .visible
                ) {
                    Button("Confirm", role: .destructive) {
                        deleteItems(listManager.selectedItems)
                        listManager.selectedItemIds = []
                        listManager.selectedItems = []
                    }
                } message: {
                    Text(
                        "This action is irreversible."
                    )
                }

                Spacer()

                Button(
                    "Transfer",
                    systemImage: "arrow.forward.folder"
                ) {

                }
                .disabled(listManager.selectedItemIds.isEmpty)
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
        deleteItems(sortedCheckedItems)
    }

    private func deleteEntireList() {
        guard let checklist else {
            return
        }

        closeChecklist()

        modelContext.delete(checklist)

        do {
            try modelContext.save()
        } catch {
            assertionFailure(
                "Failed to delete list: \(error)"
            )
        }
    }

    private func deleteItems(_ items: [ChecklistItem]) {
        items.forEach { modelContext.delete($0) }

        do {
            try modelContext.save()
        } catch {
            assertionFailure(
                "Failed to delete items: \(error)"
            )
        }
    }
}
