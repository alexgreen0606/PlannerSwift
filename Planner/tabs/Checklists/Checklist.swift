//
//  ChecklistView.swift
//  Planner
//
//  Created by Alex Green on 12/14/25.
//

import SwiftData
import SwiftDate
import SwiftUI

struct ChecklistView: View {
    let checklist: ChecklistItem

    @Environment(\.modelContext) private var modelContext

    @AppStorage("showCheckedItems") var showCheckedItems: Bool = false

    @State private var scrollProxy: ScrollViewProxy?

    var sortedCheckedItems: [ChecklistItem] {
        checklist.items
            .filter { $0.isChecked }
            .sorted { $0.sortIndex < $1.sortIndex }
    }

    var sortedUncheckedItems: [ChecklistItem] {
        checklist.items
            .filter { !$0.isChecked }
            .sorted { $0.sortIndex < $1.sortIndex }
    }

    var body: some View {
        ScrollViewReader { proxy in
            SortableListView(
                uncheckedItems: sortedUncheckedItems,
                checkedItems: sortedCheckedItems,
                showChecked: showCheckedItems,
                floatingInfo: EmptyView(),
                endAdornment: { _ in EmptyView() },
                customToggleConfig: nil,
                checkedHeader: "Completed items",
                checkedFooter: nil,
                onCreateItem: handleCreateEvent,
                onTitleChange: { _ in },
                onMoveUncheckedItem: handleMoveItem
            )
            .accentColor(checklist.color.swiftUIColor)
            .navigationTitle(checklist.title)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showCheckedItems.toggle()
                        } label: {
                            Text(
                                showCheckedItems
                                    ? "Hide complete" : "Show complete"
                            )
                            Image(
                                systemName: showCheckedItems
                                    ? "eye.slash.fill" : "eye.fill"
                            )
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add", systemImage: "plus") {
                        handleCreateEvent(at: sortedUncheckedItems.count)
                        slideTo("bottom", at: .top, withDelay: .seconds(1))
                    }
                }
            }
        }
    }

    private func handleCreateEvent(at index: Int) {
        let sortIndex = generateSortIndex(
            index: index,
            items: sortedUncheckedItems
        )
        let newItem = ChecklistItem(sortIndex: sortIndex, parent: checklist)
        modelContext.insert(newItem)
        try! modelContext.save()
    }

    private func handleMoveItem(from: Int, to: Int) {
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

    private func slideTo(
        _ id: any Hashable,
        at anchor: UnitPoint,
        withDelay delay: DispatchTimeInterval = .seconds(0)
    ) {
        guard let proxy = scrollProxy
        else { return }
        DispatchQueue.main.asyncAfter(
            deadline: .now() + delay
        ) {
            withAnimation(.linear(duration: 2)) {
                proxy.scrollTo(id, anchor: anchor)
            }
        }
    }
}
