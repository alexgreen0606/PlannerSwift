//
//  SortableListView.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import Combine
import SwiftUI

class FocusController: ObservableObject {
    @Published var focusedId: ObjectIdentifier?
}

struct SortableListView<Item: ListItem>: View {
    var items: [Item]
    var accentColor: Color = .blue
    var topInset: CGFloat = 0
    var bottomInset: CGFloat = 0
    var itemTextColorsMap: [ObjectIdentifier: Color] = [:]
    var selectedItemIds: Set<ObjectIdentifier> = []
    var disabledItemIds: Set<ObjectIdentifier> = []
    var scrollProxy: ScrollViewProxy? = nil
    
    var onCreateItem: (_ baseId: ObjectIdentifier?, _ offset: Int?) -> Void
    var onToggleItem: (_ id: ObjectIdentifier) -> Void
    var onValueChange: (_ id: ObjectIdentifier, _ value: String) -> Void
    var onMoveItem: (_ from: Int, _ to: Int) -> Void

    @StateObject var focusController = FocusController()

    var body: some View {
            List {
                Section {
                    HStack {
                        // TODO: add floating chips here
                    }
                    .opacity(0)
                }
                .listRowInsets(EdgeInsets())
                .listSectionSeparator(.hidden)
                Section {
                    // Upper Item Trigger
                    NewListItemTrigger(onCreateItem: {
                        onCreateItem(items.first?.id, nil)
                    })
                }
                .listRowInsets(EdgeInsets())
                .listSectionSeparator(.hidden, edges: .top)
                .listSectionSeparator(
                    items.isEmpty ? .hidden : .visible,
                    edges: .bottom
                )
                .listSectionSeparatorTint(
                    Color(uiColor: .quaternaryLabel)
                )
                Section {
                    ForEach(items, id: \.self) { item in
                        ListItemView<Item>(
                            item: item,
                            isSelected: selectedItemIds.contains(item.id),
                            isSelectDisabled: disabledItemIds.contains(
                                item.id
                            ),
                            accentColor: accentColor,
                            textColor: itemTextColorsMap[item.id]
                                ?? Color(uiColor: .label),
                            onCreateItem: onCreateItem,
                            onToggleItem: onToggleItem,
                            onValueChange: onValueChange,
                        )
                        .id(item.id)
                        .environmentObject(focusController)
                    }
                    .onMove(perform: handleMove)
                } footer: {
                    // Lower Item Trigger
                    NewListItemTrigger(onCreateItem: handleCreateLowerItem)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden, edges: .bottom)
                }
            }
            .refreshable {}
            .overlay(alignment: .top) {
                // TODO: put floating chips here
            }
            .listStyle(.plain)
            .environment(\.defaultMinListRowHeight, 0)
            .animation(.default, value: items)
            .safeAreaPadding(.top, topInset)
            .safeAreaPadding(.bottom, bottomInset)
    }

    private func handleMove(from sources: IndexSet, to destination: Int) {
        for source in sources {
            var to = destination

            if to > source {
                to -= 1
            }

            onMoveItem(source, to)
        }
    }

    private func handleCreateLowerItem() {
        let baseId = items.last?.id
        onCreateItem(baseId, 1)
    }
}
