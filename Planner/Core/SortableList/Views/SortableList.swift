//
//  SortableList.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import Combine
import SwiftData
import SwiftUI

// Clean

struct SortableListView<
    Item: ListItem,
    LeftAdornment: View,
    RightAdornment: View,
    BottomAdornment: View,
    FloatingInfo: View
>: View {
    private let uncheckedItems: [Item]
    private let checkedItems: [Item]
    private let rowId: (_ item: Item) -> String
    private let showChecked: Bool
    private let floatingInfo: FloatingInfo?
    private let checkedHeader: String
    private let checkedFooter: String?
    private let emptyUncheckedLabel: String
    private let emptyCheckedLabel: String
    private let namespace: Namespace.ID?
    private let tint: (_ item: Item) -> Color
    private let toolbarSystemImageNames: [String]
    private let onToolbarTap: ((String, Item) -> Void)?
    private let toggleConfig: (_ item: Item) -> ToggleConfig?
    private let leftAdornment: (_ item: Item) -> LeftAdornment
    private let rightAdornment: (_ item: Item) -> RightAdornment
    private let bottomAdornment: (_ item: Item) -> BottomAdornment
    private let scrollProxy: ScrollViewProxy?
    private let createItem: (_ at: Int) -> Void
    private let deleteItem: ((_: Item) -> Void)?
    private let handleTitleChange: ((_ item: Item) -> Void)?
    private let moveItem: (_ from: Int, _ to: Int) -> Void

    init(
        uncheckedItems: [Item],
        checkedItems: [Item] = [],
        rowId: @escaping (_ item: Item) -> String = { "\($0.stableId)" },
        showChecked: Bool = false,
        checkedHeader: String = "",
        emptyUncheckedLabel: String,
        emptyCheckedLabel: String = "",
        tint: @escaping (_: Item) -> Color,
        scrollProxy: ScrollViewProxy? = nil,
        createItem: @escaping (_: Int) -> Void,
        deleteItem: ((_: Item) -> Void)? = nil,
        moveItem: @escaping (_: Int, _: Int) -> Void,
        floatingInfo: FloatingInfo? = EmptyView(),
        namespace: Namespace.ID? = nil,
        toolbarSystemImageNames: [String] = [],
        onToolbarTap: ((String, Item) -> Void)? = nil,
        toggleConfig: @escaping (_: Item) -> ToggleConfig? = { _ in nil },
        leftAdornment: @escaping (_: Item) -> LeftAdornment = { _ in
            EmptyView() as! LeftAdornment
        },
        rightAdornment: @escaping (_: Item) -> RightAdornment = { _ in
            EmptyView() as! RightAdornment
        },
        bottomAdornment: @escaping (_: Item) -> BottomAdornment = { _ in
            EmptyView() as! BottomAdornment
        },
        handleTitleChange: ((_: Item) -> Void)? = nil,
        checkedFooter: String? = nil
    ) {
        self.uncheckedItems = uncheckedItems
        self.checkedItems = checkedItems
        self.rowId = rowId
        self.showChecked = showChecked
        self.floatingInfo = floatingInfo
        self.checkedHeader = checkedHeader
        self.checkedFooter = checkedFooter
        self.emptyUncheckedLabel = emptyUncheckedLabel
        self.emptyCheckedLabel = emptyCheckedLabel
        self.namespace = namespace
        self.tint = tint
        self.toolbarSystemImageNames = toolbarSystemImageNames
        self.onToolbarTap = onToolbarTap
        self.toggleConfig = toggleConfig
        self.leftAdornment = leftAdornment
        self.rightAdornment = rightAdornment
        self.bottomAdornment = bottomAdornment
        self.scrollProxy = scrollProxy
        self.createItem = createItem
        self.handleTitleChange = handleTitleChange
        self.moveItem = moveItem
        self.deleteItem = deleteItem
    }

    @Environment(\.scenePhase) private var appPhase
    @EnvironmentObject private var ListEngine: ListEngine<Item>

    var body: some View {
        let list = List {
            uncheckedList
            checkedList
        }
        .listStyle(.plain)
        .environment(\.defaultMinListRowHeight, 0)
        .safeAreaPadding(.bottom, 20)
        .background(Color.appBackground.edgesIgnoringSafeArea(.all))
        .overlay {
            if uncheckedItems.isEmpty && !showChecked {
                EmptyLabelView(emptyUncheckedLabel)
            }
        }
        .animateSynchronousAction(from: uncheckedItems)
        // Blur the textfield when the list unmounts (deletes empty items).
        .onDisappear {
            ListEngine.focusedId = nil
        }

        // Blur the textfield when the app exits focus (deletes empty items).
        .onChange(of: appPhase) { _, phase in
            if phase == .inactive {
                ListEngine.focusedId = nil
            }
        }

        if let scrollProxy {
            list
                // Slide to checked items when the user marks them visible.
                .withScrollTrigger(
                    scrollProxy: scrollProxy,
                    trigger: showChecked,
                    id: ListIds.CHECKED_ITEMS,
                    disabled: !showChecked
                )
        } else {
            list
        }
    }

    // MARK: - View Builders

    private var uncheckedList: some View {
        Section {
            SeparatorView {
                attemptCreateItem(at: 0)
            }
            .discreetListItem()
            .listRowInsets(EdgeInsets())

            ForEach(Array(uncheckedItems.enumerated()), id: \.element.stableId)
            { index, item in
                RowView(
                    item: item,
                    index: index,
                    showChecked: showChecked,
                    isUpperItem: item.stableId
                        == uncheckedItems.first?.stableId,
                    tint: tint(item),
                    leftAdornment: leftAdornment(item),
                    rightAdornment: rightAdornment(item),
                    bottomAdornment: bottomAdornment(item),
                    toolbarSystemImageNames: toolbarSystemImageNames,
                    customToggleConfig: toggleConfig(item),
                    namespace: namespace,
                    createItem: attemptCreateItem,
                    deleteItem: deleteItem,
                    onToolbarTap: onToolbarTap,
                    onTitleChange: handleTitleChange
                )
                .id(rowId(item))
            }
            .onMove(perform: handleRowMove)

            SeparatorView {
                attemptCreateItem(at: uncheckedItems.count)
            }
            .discreetListItem()
            .listRowInsets(EdgeInsets())
            .id(ListIds.UNCHECKED_ITEMS)

            if uncheckedItems.isEmpty && showChecked {
                EmptyLabelView(emptyUncheckedLabel)
                    .discreetListItem()
                    .frame(maxWidth: .infinity)
                    .frame(height: ListLayout.EMPTY_LABEL_HEIGHT)
            }

        } header: {
            floatingInfo
                .listRowInsets(.vertical, 0)
        }
        .listSectionSeparator(.hidden)
        .listSectionMargins(.top, 0)
    }

    @ViewBuilder
    private var checkedList: some View {
        if showChecked {
            Section {
                ForEach(
                    Array(checkedItems.enumerated()),
                    id: \.element.stableId
                ) { index, item in
                    RowView(
                        item: item,
                        index: index,
                        showChecked: showChecked,
                        isUpperItem: item.stableId
                            == checkedItems.first?.stableId,
                        tint: tint(item),
                        leftAdornment: leftAdornment(item),
                        rightAdornment: rightAdornment(item),
                        bottomAdornment: bottomAdornment(item),
                        toggleOnlyMode: true,
                        customToggleConfig: toggleConfig(item)
                    )
                }

                if checkedItems.isEmpty {
                    EmptyLabelView(emptyCheckedLabel)
                        .discreetListItem()
                        .frame(maxWidth: .infinity)
                        .frame(height: ListLayout.EMPTY_LABEL_HEIGHT)
                }
            } header: {
                Text(checkedHeader)
            } footer: {
                if checkedFooter != nil && !checkedItems.isEmpty {
                    Text(checkedFooter!)
                        .font(.footnote)
                        .foregroundStyle(Color.secondary)
                }
            }
            .discreetListItem()
            .id(ListIds.CHECKED_ITEMS)
        }
    }

    // MARK: - Functions

    private func handleRowMove(
        from sources: IndexSet,
        to destination: Int
    ) {
        for source in sources {
            moveItem(source, destination)
        }
    }

    private func attemptCreateItem(at index: Int) {
        guard canCreateItem(at: index, in: uncheckedItems) else {
            return
        }
        createItem(index)
    }
}
