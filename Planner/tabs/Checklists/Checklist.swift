//
//  ChecklistView.swift
//  Planner
//
//  Created by Alex Green on 12/14/25.
//

import SwiftData
import SwiftUI

struct ChecklistView: View {
    let checklist: ChecklistItem

    @Environment(\.modelContext) private var modelContext

    @State private var scrollProxy: ScrollViewProxy?

    private var sortedCheckedItems: [ChecklistItem] {
        checklist.items
            .filter { $0.isChecked }
            .sorted { $0.sortIndex < $1.sortIndex }
    }

    private var sortedUncheckedItems: [ChecklistItem] {
        checklist.items
            .filter { !$0.isChecked }
            .sorted { $0.sortIndex < $1.sortIndex }
    }

    var body: some View {
        ScrollViewReader { proxy in
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
                tint: checklist.color.swiftUIColor,
                getEndAdornment: { _ in EmptyView() },
                createItem: createItem,
                handleTitleChange: { _ in },
                moveItem: moveItem
            )
            .accentColor(checklist.color.swiftUIColor)
            .navigationTitle(checklist.title)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            checklist.showCompleted.toggle()
                        } label: {
                            Text(
                                checklist.showCompleted
                                    ? "Hide completed" : "Show completed"
                            )
                            Image(
                                systemName: checklist.showCompleted
                                    ? "eye.slash" : "eye"
                            )
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add", systemImage: "plus") {
                        createItem(at: sortedUncheckedItems.count)
                        scrollProxy?.slideTo(
                            "UNCHECKED",
                            at: .bottom,
                            withDelay: .seconds(1)
                        )
                    }
                }
            }
        }
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
}
