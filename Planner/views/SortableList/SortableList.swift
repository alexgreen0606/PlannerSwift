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
>: View {
    private let uncheckedItems: [Item]
    private let checkedItems: [Item]
    private let showChecked: Bool
    private let floatingInfo: FloatingInfo?
    private let customToggleConfig: RowToggleConfig<Item>?
    private let checkedHeader: String
    private let checkedFooter: String?
    private let emptyUncheckedLabel: String
    private let emptyCheckedLabel: String
    private let namespace: Namespace.ID?
    private let tint: (_ item: Item) -> Color
    private let toolbarIcons: [String]
    private let tapToolbar: ((String, Item) -> Void)?
    private let leftAdornment: (_ item: Item) -> LeftAdornment
    private let rightAdornment: (_ item: Item) -> RightAdornment
    private let bottomAdornment: (_ item: Item) -> BottomAdornment
    private let scrollProxy: ScrollViewProxy
    private let createItem: (_ baseId: UUID?, _ offset: Int) -> Void
    private let handleTitleChange: ((_ item: Item) -> Void)?
    private let moveItem: (_ from: Int, _ to: Int) -> Void

    init(
        uncheckedItems: [Item],
        checkedItems: [Item],
        showChecked: Bool,
        checkedHeader: String,
        emptyUncheckedLabel: String,
        emptyCheckedLabel: String,
        tint: @escaping (_: Item) -> Color,
        scrollProxy: ScrollViewProxy,
        createItem: @escaping (_: UUID?, _: Int) -> Void,
        moveItem: @escaping (_: Int, _: Int) -> Void,
        floatingInfo: FloatingInfo? = EmptyView(),
        customToggleConfig: RowToggleConfig<Item>? = nil,
        namespace: Namespace.ID? = nil,
        toolbarIcons: [String] = [],
        tapToolbar: ((String, Item) -> Void)? = nil,
        leftAdornment: @escaping (_: Item) -> LeftAdornment = { _ in EmptyView() as! LeftAdornment
        },
        rightAdornment: @escaping (_: Item) -> RightAdornment = { _ in
            EmptyView() as! RightAdornment
        },
        bottomAdornment: @escaping (_: Item) -> BottomAdornment = { _ in
            EmptyView() as! BottomAdornment
        },
        handleTitleChange: ((_: Item) -> Void)? = nil,
        checkedFooter: String? = nil,
    ) {
        self.uncheckedItems = uncheckedItems
        self.checkedItems = checkedItems
        self.showChecked = showChecked
        self.floatingInfo = floatingInfo
        self.customToggleConfig = customToggleConfig
        self.checkedHeader = checkedHeader
        self.checkedFooter = checkedFooter
        self.emptyUncheckedLabel = emptyUncheckedLabel
        self.emptyCheckedLabel = emptyCheckedLabel
        self.namespace = namespace
        self.tint = tint
        self.toolbarIcons = toolbarIcons
        self.tapToolbar = tapToolbar
        self.leftAdornment = leftAdornment
        self.rightAdornment = rightAdornment
        self.bottomAdornment = bottomAdornment
        self.scrollProxy = scrollProxy
        self.createItem = createItem
        self.handleTitleChange = handleTitleChange
        self.moveItem = moveItem
    }

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
                        showChecked: showChecked,
                        isUpperItem: item.stableId
                            == uncheckedItems.first?.stableId,
                        tint: tint(item),
                        leftAdornment: leftAdornment(item),
                        rightAdornment: rightAdornment(item),
                        bottomAdornment: bottomAdornment(item),
                        toolbarIcons: toolbarIcons,
                        customToggleConfig: customToggleConfig,
                        namespace: namespace,
                        createItem: createItem,
                        onToolbarTap: handleToolbarPress,
                        onTitleChange: handleTitleChange
                    )
                    .id(item.stableId)
                }
                .onMove(perform: moveUncheckedItem)

                NewRowTriggerView {
                    createItem(uncheckedItems.last?.stableId, 1)
                }
                .discreetListItem()
                .listRowInsets(EdgeInsets())
                .id(IdConstants.UNCHECKED_ITEMS)

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
                            showChecked: showChecked,
                            isUpperItem: item.stableId
                                == checkedItems.first?.stableId,
                            tint: tint(item),
                            leftAdornment: leftAdornment(item),
                            rightAdornment: rightAdornment(item),
                            bottomAdornment: bottomAdornment(item)
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
                .id(IdConstants.CHECKED_ITEMS)
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
        .animateSynchronousAction(from: uncheckedItems)
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
            id: IdConstants.CHECKED_ITEMS,
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
    }

}
