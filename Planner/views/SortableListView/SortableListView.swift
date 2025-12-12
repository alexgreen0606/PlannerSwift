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

struct SortableListView<Item: ListItem, EndAdornment: View>: View {
    let uncheckedItems: [Item]
    let checkedItems: [Item]
    let toggleType: ListToggleType = .storage
    let accentColor: Color = .accentColor
    let itemTextColorsMap: [ObjectIdentifier: Color] = [:]  // TODO: is this prop needed?
    let disabledItemIds: Set<ObjectIdentifier> = []
    let endAdornment: ((_ item: Item) -> EndAdornment)?
    let customToggleConfig: CustomIconConfig?
    let checkedHeader: String
    let checkedFooter: String?
    let onCreateItem: (_ index: Int) -> Void
    let onTitleChange: (_ item: Item) -> Void
    let onMoveUncheckedItem: (_ from: Int, _ to: Int) -> Void
    let onMoveCheckedItem: (_ from: Int, _ to: Int) -> Void

    @EnvironmentObject var listManager: ListManager

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
                NewItemTriggerView {
                    handleCreateItem(
                        baseId: uncheckedItems.first?.id,
                        offset: 0
                    )
                }
            }
            .listRowInsets(EdgeInsets())
            .listSectionSeparator(.hidden)
            Section {
                ForEach(uncheckedItems, id: \.self) { item in
                    ItemView(
                        item: item,
                        toggleType: toggleType,
                        isSelectDisabled: disabledItemIds.contains(
                            item.id
                        ),
                        accentColor: accentColor,
                        textColor: itemTextColorsMap[item.id]
                            ?? Color(uiColor: .label),
                        showUpperDivider: item.id == uncheckedItems.first?.id,
                        endAdornment: endAdornment,
                        customToggleConfig: customToggleConfig,
                        onCreateItem: handleCreateItem,
                        onTitleChange: onTitleChange,
                    )
                    .id(item.id)
                }
                .onMove(perform: handleMoveUncheckedItem)
            } footer: {
                NewItemTriggerView {
                    handleCreateLowerItem()
                }
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .id("bottom")
            }

            // TODO: deselecting item and then focusing it loses focus after movement to new list
            if listManager.showChecked {
                Section{
                    ForEach(checkedItems, id: \.self) { item in
                        ItemView(
                            item: item,
                            toggleType: toggleType,
                            isSelectDisabled: disabledItemIds.contains(
                                item.id
                            ),
                            accentColor: accentColor,
                            textColor: itemTextColorsMap[item.id]
                            ?? Color(uiColor: .label),
                            showUpperDivider: item.id
                            == checkedItems.first?.id,
                            endAdornment: endAdornment,
                            customToggleConfig: customToggleConfig,
                            onCreateItem: { _, _ in },
                            onTitleChange: { _ in },
                        )
                        .id(item.id)
                    }
                    .onMove(perform: handleMoveCheckedItem)
                } header: {
                    Text(checkedHeader)
                } footer: {
                    if checkedFooter != nil {
                        Text(checkedFooter!)
                            .font(.footnote)
                            .foregroundStyle(Color(uiColor: .secondaryLabel))
                    }
                }
                .listSectionSeparator(.hidden)
                .id("checked")
            }
        }
        .environmentObject(focusController)
        .refreshable {}
        .overlay(alignment: .top) {
            // TODO: floating chips here
        }
        .listStyle(.plain)
        .environment(\.defaultMinListRowHeight, 0)
        .animation(.linear(duration: 0.2), value: uncheckedItems)
        .safeAreaPadding(.bottom, 20)
    }

    private func handleCreateItem(
        baseId: ObjectIdentifier?,
        offset: Int?
    ) {
        guard
            let baseIndex = uncheckedItems.firstIndex(where: {
                $0.id == baseId
            })
        else {
            return
        }
        let finalIndex = baseIndex + (offset ?? 0)

        // Don't create the new item if it is next to an empty item.
        let upperEvent = finalIndex > 0 ? uncheckedItems[finalIndex - 1] : nil
        let lowerEvent =
            finalIndex < uncheckedItems.count ? uncheckedItems[finalIndex] : nil
        if let upper = upperEvent, upper.title.isEmpty {
            return
        }
        if let lower = lowerEvent, lower.title.isEmpty {
            return
        }

        onCreateItem(finalIndex)
    }

    private func handleMoveUncheckedItem(from sources: IndexSet, to destination: Int) {
        for source in sources {
            var to = destination

            if to > source {
                to -= 1
            }

            onMoveUncheckedItem(source, to)
        }
    }
    
    private func handleMoveCheckedItem(from sources: IndexSet, to destination: Int) {
        for source in sources {
            var to = destination

            if to > source {
                to -= 1
            }

            onMoveCheckedItem(source, to)
        }
    }

    private func handleCreateLowerItem() {
        let baseId = uncheckedItems.last?.id
        handleCreateItem(baseId: baseId, offset: 1)
    }
}
