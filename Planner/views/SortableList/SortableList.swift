//
//  SortableListView.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import Combine
import SwiftData
import SwiftUI

struct SortableListView<
    Item: ListItem,
    LeftAdornment: View,
    RightAdornment: View,
    BottomAdornment: View,
    FloatingInfo: View
>:
    View
{
    let uncheckedItems: [Item]
    let checkedItems: [Item]
    let showChecked: Bool
    let floatingInfo: FloatingInfo?
    let customToggleConfig: RowToggleConfig<Item>?
    let checkedHeader: String
    let checkedFooter: String?
    let emptyUncheckedLabel: String
    let emptyCheckedLabel: String
    let namespace: Namespace.ID?
    let tint: (_ item: Item) -> Color
    let toolbarIcons: [String]
    let tapToolbar: ((String, Item) -> Void)?
    let leftAdornment: ((_ item: Item) -> LeftAdornment)?
    let rightAdornment: ((_ item: Item) -> RightAdornment)?
    let bottomAdornment: ((_ item: Item) -> BottomAdornment)?
    let scrollProxy: ScrollViewProxy
    let createItem: (_ baseId: UUID?, _ offset: Int) -> Void
    let handleTitleChange: (_ item: Item) -> Void
    let moveItem: (_ from: Int, _ to: Int) -> Void
    let isItemChecked: ((_ item: Item) -> Bool)?

    @Environment(\.scenePhase) private var appPhase
    @EnvironmentObject private var listManager: ListManager<Item>

    var body: some View {
        List {
            Section {
                NewRowTriggerView {
                    createItem(
                        uncheckedItems.first?.stableId,
                        0
                    )
                }
                .discreetListItem()
                .listRowInsets(EdgeInsets())

                ForEach(uncheckedItems, id: \.stableId) { item in
                    RowView(
                        item: item,
                        tint: tint,
                        showChecked: showChecked,
                        showUpperDivider: item.stableId == uncheckedItems.first?.stableId,
                        toolbarIcons: toolbarIcons,
                        tapToolbar: handleToolbarPress,
                        leftAdornment: leftAdornment,
                        rightAdornment: rightAdornment,
                        bottomAdornment: bottomAdornment,
                        namespace: namespace,
                        customToggleConfig: customToggleConfig,
                        onCreateItem: createItem,
                        onTitleChange: handleTitleChange,
                        isItemChecked: isItemChecked
                    )
                    .id(item.stableId)
                }
                .onMove(perform: moveUncheckedItem)

                NewRowTriggerView {
                    createItem(uncheckedItems.last?.stableId, 1)
                }
                .discreetListItem()
                .listRowInsets(EdgeInsets())
                .id(IDConstants.UNCHECKED_ITEMS)

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
                    ForEach(checkedItems, id: \.stableId) { item in
                        RowView(
                            item: item,
                            tint: tint,
                            showChecked: true,
                            showUpperDivider: item.stableId
                                == checkedItems.first?.stableId,
                            toolbarIcons: toolbarIcons,
                            tapToolbar: { _, _ in },
                            leftAdornment: leftAdornment,
                            rightAdornment: rightAdornment,
                            bottomAdornment: bottomAdornment,
                            namespace: namespace,
                            customToggleConfig: customToggleConfig,
                            onCreateItem: { _, _ in },
                            onTitleChange: { _ in },
                            isItemChecked: isItemChecked
                        )
                    }
                } header: {
                    Text(
                        checkedItems.isEmpty ? emptyCheckedLabel : checkedHeader
                    )
                } footer: {
                    if checkedFooter != nil && !checkedItems.isEmpty {
                        Text(checkedFooter!)
                            .font(.footnote)
                            .foregroundStyle(Color.secondary)
                    }
                }
                .discreetListItem()
                .id(IDConstants.CHECKED_ITEMS)
            }
        }
        .listStyle(.plain)
        .environment(\.defaultMinListRowHeight, 0)
        .safeAreaPadding(.bottom, 20)
        .background(Color.appBackground.edgesIgnoringSafeArea(.all))
        .overlay {
            if uncheckedItems.isEmpty && !showChecked {
                EmptyLabel(emptyUncheckedLabel)
            }
        }
        .animateSynchronousAction(from: uncheckedItems.count)
        .animateSynchronousAction(from: listManager.newlyCheckedIds)
        .animateSynchronousAction(from: listManager.newlyUncheckedIds)

        // Blur the textfield when the list unmounts (deletes empty items).
        .onDisappear {
            listManager.focusedId = nil
        }
        
        // Blur the textfields when the app exits focus.
        .onChange(of: appPhase) { _, phase in
            if phase == .inactive {
                listManager.focusedId = nil
            }
        }

        // Slide to checked items when the user marks them visible.
        .withScrollTrigger(
            scrollProxy: scrollProxy,
            trigger: showChecked,
            id: IDConstants.CHECKED_ITEMS,
            disabled: !showChecked
        )
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

    private func handleToolbarPress(_ iconName: String, _ item: Item) {
        tapToolbar?(iconName, item)
        listManager.focusedId = nil
    }

}
