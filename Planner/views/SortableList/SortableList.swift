//
//  SortableListView.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import Combine
import SwiftData
import SwiftUI

class FocusController: ObservableObject {
    @Published var focusedId: PersistentIdentifier?
}

struct SortableListView<Item: ListItem, EndAdornment: View, FloatingInfo: View>:
    View
{
    let uncheckedItems: [Item]
    let checkedItems: [Item]
    let showChecked: Bool
    let disabledItemIds: Set<PersistentIdentifier> = []
    let floatingInfo: FloatingInfo?
    let customToggleConfig: CustomIconConfig<Item>?
    let checkedHeader: String
    let checkedFooter: String?
    let emptyUncheckedLabel: String
    let emptyCheckedLabel: String
    let tint: Color
    let getEndAdornment: ((_ item: Item) -> EndAdornment)?
    let createItem: (_ baseId: PersistentIdentifier?, _ offset: Int) -> Void
    let handleTitleChange: (_ item: Item) -> Void
    let moveItem: (_ from: Int, _ to: Int) -> Void
    let isItemChecked: ((_ item: Item) -> Bool)?

    @EnvironmentObject var listManager: ListManager<Item>

    @StateObject var focusController = FocusController()

    var body: some View {
        List {
            Section {
                NewItemTriggerView {
                    createItem(
                        uncheckedItems.first?.id,
                        0
                    )
                }
                .discreetListItem()
                .listRowInsets(EdgeInsets())

                ForEach(uncheckedItems) { item in
                    ItemView(
                        item: item,
                        tint: tint,
                        showChecked: showChecked,
                        isSelectDisabled: disabledItemIds.contains(
                            item.id
                        ),
                        showUpperDivider: item.id == uncheckedItems.first?.id,
                        endAdornment: getEndAdornment,
                        customToggleConfig: customToggleConfig,
                        onCreateItem: createItem,
                        onTitleChange: handleTitleChange,
                        isItemChecked: isItemChecked
                    )
                    .id(item.id)
                }
                .onMove(perform: moveUncheckedItem)

                NewItemTriggerView {
                    createItem(uncheckedItems.last?.id, 1)
                }
                .discreetListItem()
                .listRowInsets(EdgeInsets())
                .id("UNCHECKED")

                if uncheckedItems.isEmpty && showChecked {
                    EmptyLabel(emptyUncheckedLabel)
                        .discreetListItem()
                        .frame(maxWidth: .infinity)
                }

            } header: {
                floatingInfo
                    .listRowInsets(.top, 0)
            }
            .listSectionSeparator(.hidden)

            if showChecked {
                Section {
                    ForEach(checkedItems) { item in
                        ItemView(
                            item: item,
                            tint: tint,
                            showChecked: true,
                            isSelectDisabled: disabledItemIds.contains(
                                item.id
                            ),
                            showUpperDivider: item.id
                                == checkedItems.first?.id,
                            endAdornment: getEndAdornment,
                            customToggleConfig: customToggleConfig,
                            onCreateItem: { _, _ in },
                            onTitleChange: { _ in },
                            isItemChecked: isItemChecked
                        )
                        .id(item.id)
                    }
                } header: {
                    Text(
                        checkedItems.isEmpty ? emptyCheckedLabel : checkedHeader
                    )
                } footer: {
                    if checkedFooter != nil && !checkedItems.isEmpty {
                        Text(checkedFooter!)
                            .font(.footnote)
                            .foregroundStyle(Color(uiColor: .secondaryLabel))
                    }
                }
                .discreetListItem()
                .id("CHECKED")
            }
        }
        .environmentObject(focusController)
        .listStyle(.plain)
        .environment(\.defaultMinListRowHeight, 0)
        .safeAreaPadding(.bottom, 20)
        .background(Color.appBackground.edgesIgnoringSafeArea(.all))
        .overlay {
            if uncheckedItems.isEmpty && !showChecked {
                EmptyLabel(emptyUncheckedLabel)
            }
        }
        .animation(.linear(duration: 0.2), value: uncheckedItems)
        .animation(.linear(duration: 0.2), value: listManager.newlyCheckedIds)
        .animation(.linear(duration: 0.2), value: listManager.newlyUncheckedIds)
        // Blur the textfield when the list unmounts (deletes empty items).
        .onDisappear {
            focusController.focusedId = nil
        }
    }

    private func moveUncheckedItem(
        from sources: IndexSet,
        to destination: Int
    ) {
        for source in sources {
            var to = destination

            if to > source {
                to -= 1
            }

            moveItem(source, to)
        }
    }

}
