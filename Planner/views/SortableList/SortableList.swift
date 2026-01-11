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

struct SortableListView<Item: ListItem, EndAdornment: View, FloatingInfo: View>:
    View
{
    let uncheckedItems: [Item]
    let checkedItems: [Item]
    let showChecked: Bool
    let toggleType: ListToggleType = .storage
    let disabledItemIds: Set<ObjectIdentifier> = []
    let floatingInfo: FloatingInfo?
    let customToggleConfig: CustomIconConfig?
    let checkedHeader: String
    let checkedFooter: String?
    let emptyUncheckedLabel: String
    let emptyCheckedLabel: String
    let tint: Color
    let getEndAdornment: ((_ item: Item) -> EndAdornment)?
    let createItem: (_ index: Int) -> Void
    let handleTitleChange: (_ item: Item) -> Void
    let moveItem: (_ from: Int, _ to: Int) -> Void

    @EnvironmentObject var listManager: ListManager
    
    @StateObject var focusController = FocusController()

    var body: some View {
        List {
            Section {
                NewItemTriggerView {
                    handleCreateItem(
                        baseId: uncheckedItems.first?.id,
                        offset: 0
                    )
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)

                ForEach(uncheckedItems) { item in
                    ItemView(
                        item: item,
                        tint: tint,
                        showChecked: showChecked,
                        toggleType: toggleType,
                        isSelectDisabled: disabledItemIds.contains(
                            item.id
                        ),
                        showUpperDivider: item.id == uncheckedItems.first?.id,
                        endAdornment: getEndAdornment,
                        customToggleConfig: customToggleConfig,
                        onCreateItem: handleCreateItem,
                        onTitleChange: handleTitleChange,
                    )
                    .id(item.id)
                }
                .onMove(perform: moveUncheckedItem)

                NewItemTriggerView {
                    createLowerItem()
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .id("UNCHECKED")

                if uncheckedItems.isEmpty && showChecked
                {
                    VStack(alignment: .center) {
                        Text(emptyUncheckedLabel)
                            .font(
                                .system(
                                    size: 16,
                                    weight: .heavy,
                                    design: .rounded
                                )
                            )
                            .foregroundStyle(Color(uiColor: .tertiaryLabel))
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 90, alignment: .center)
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
                            toggleType: toggleType,
                            isSelectDisabled: disabledItemIds.contains(
                                item.id
                            ),
                            showUpperDivider: item.id
                                == checkedItems.first?.id,
                            endAdornment: getEndAdornment,
                            customToggleConfig: customToggleConfig,
                            onCreateItem: { _, _ in },
                            onTitleChange: { _ in },
                        )
                        .id(item.id)
                    }
                } header: {
                    Text(checkedItems.isEmpty ? emptyCheckedLabel : checkedHeader)
                } footer: {
                    if checkedFooter != nil && !checkedItems.isEmpty {
                        Text(checkedFooter!)
                            .font(.footnote)
                            .foregroundStyle(Color(uiColor: .secondaryLabel))
                    }
                }
                .listRowBackground(Color.clear)
                .listSectionSeparator(.hidden)
                .id("CHECKED")
            }
        }
        .environmentObject(focusController)
        .listStyle(.plain)
        .environment(\.defaultMinListRowHeight, 0)
        .safeAreaPadding(.bottom, 20)
        .background(Color.appBackground)
        .overlay {
            if uncheckedItems.isEmpty && !showChecked
            {
                Text(emptyUncheckedLabel)
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(uiColor: .tertiaryLabel))
            }
        }
        .animation(.linear(duration: 0.2), value: uncheckedItems)
        .animation(.linear(duration: 0.2), value: listManager.newlyCheckedIds)
        .animation(.linear(duration: 0.2), value: listManager.newlyUncheckedIds)
    }

    private func handleCreateItem(
        baseId: ObjectIdentifier?,
        offset: Int = 0
    ) {
        guard
            let baseIndex = uncheckedItems.firstIndex(where: {
                $0.id == baseId
            })
        else {
            return
        }

        let finalIndex = baseIndex + offset

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

        createItem(finalIndex)
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

    private func createLowerItem() {
        let baseId = uncheckedItems.last?.id
        handleCreateItem(baseId: baseId, offset: 1)
    }
}
