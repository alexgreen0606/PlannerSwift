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
    private let showChecked: Bool
    private let floatingInfo: FloatingInfo?
    private let customRowToggleConfig: ToggleConfig<Item>?
    private let checkedHeader: String
    private let checkedFooter: String?
    private let emptyUncheckedLabel: String
    private let emptyCheckedLabel: String
    private let namespace: Namespace.ID?
    private let tint: (_ item: Item) -> Color
    private let toolbarSystemImageNames: [String]
    private let onToolbarTap: ((String, Item) -> Void)?
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
        customRowToggleConfig: ToggleConfig<Item>? = nil,
        namespace: Namespace.ID? = nil,
        toolbarSystemImageNames: [String] = [],
        onToolbarTap: ((String, Item) -> Void)? = nil,
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
        checkedFooter: String? = nil,
    ) {
        self.uncheckedItems = uncheckedItems
        self.checkedItems = checkedItems
        self.showChecked = showChecked
        self.floatingInfo = floatingInfo
        self.customRowToggleConfig = customRowToggleConfig
        self.checkedHeader = checkedHeader
        self.checkedFooter = checkedFooter
        self.emptyUncheckedLabel = emptyUncheckedLabel
        self.emptyCheckedLabel = emptyCheckedLabel
        self.namespace = namespace
        self.tint = tint
        self.toolbarSystemImageNames = toolbarSystemImageNames
        self.onToolbarTap = onToolbarTap
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
            uncheckedList
            checkedList
        }
        .listStyle(.plain)
        .environment(\.defaultMinListRowHeight, 0)
        .safeAreaPadding(.bottom, 20)
        .background(Color.appBackground.edgesIgnoringSafeArea(.all))
        .overlay {
            if uncheckedItems.isEmpty && !showChecked {
                EmptyLabelView(text: emptyUncheckedLabel)
            }
        }
        .animateSynchronousAction(from: uncheckedItems)

        // Blur the textfield when the list unmounts (deletes empty items).
        .onDisappear {
            listManager.focusedId = nil
        }

        // Blur the textfield when the app exits focus (deletes empty items).
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

    // MARK: - View Builders

    private var uncheckedList: some View {
        Section {
            SeparatorView {
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
                    toolbarSystemImageNames: toolbarSystemImageNames,
                    customToggleConfig: customRowToggleConfig,
                    namespace: namespace,
                    createItem: createItem,
                    onToolbarTap: onToolbarTap,
                    onTitleChange: handleTitleChange
                )
                .id(item.stableId)
            }
            .onMove(perform: handleRowMove)

            SeparatorView {
                createItem(uncheckedItems.last?.stableId, 1)
            }
            .discreetListItem()
            .listRowInsets(EdgeInsets())
            .id(IdConstants.UNCHECKED_ITEMS)

            if uncheckedItems.isEmpty && showChecked {
                EmptyLabelView(text: emptyUncheckedLabel)
                    .discreetListItem()
                    .frame(maxWidth: .infinity)
            }

        } header: {
            floatingInfo
                .listRowInsets(.top, 0)
        }
        .listSectionSeparator(.hidden)
    }

    @ViewBuilder
    private var checkedList: some View {
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
                        bottomAdornment: bottomAdornment(item),
                        toggleOnlyMode: true,
                        customToggleConfig: customRowToggleConfig
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

    // MARK: - Functions

    private func handleRowMove(
        from sources: IndexSet,
        to destination: Int
    ) {
        for source in sources {
            moveItem(source, destination)
        }
    }

}
