//
//  SortableTextfieldList.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import Combine
import SwiftData
import SwiftUI

struct SortableTextfieldListView<
    Item: ListItemDetails,
    FloatingInfo: View,
    LeftAdornment: View,
    RightAdornment: View,
    BottomAdornment: View
>: View {
    private let sortedItems: [Item]
    private let itemsLabel: String
    private let floatingInfo: FloatingInfo?
    private let createItem: (_ at: Int) -> Void
    private let moveItem: (_ from: Int, _ to: Int) -> Void
    private let deleteItem: ((_: Item) -> Void)?
    private let handleTitleChange: ((_ item: Item) -> Void)?

    private let sortedPendingItems: [Item]

    private let sortedCompletedItems: [Item]
    private let showCompleted: Bool
    private let completedFooter: String?

    private let rowId: (_ item: Item) -> String
    private let tint: (_ item: Item) -> Color
    private let toggleConfig: (_ item: Item) -> ToggleConfig?
    private let leftAdornment: (_ item: Item) -> LeftAdornment
    private let rightAdornment: (_ item: Item) -> RightAdornment
    private let bottomAdornment: (_ item: Item) -> BottomAdornment

    private let scrollProxy: ScrollViewProxy
    private let namespace: Namespace.ID?
    private let settings: Settings

    init(
        sortedItems: [Item],
        itemsLabel: String = "Items",
        floatingInfo: FloatingInfo? = EmptyView(),
        createItem: @escaping (_: Int) -> Void,
        moveItem: @escaping (_: Int, _: Int) -> Void,
        deleteItem: ((_: Item) -> Void)? = nil,
        handleTitleChange: ((_: Item) -> Void)? = nil,
        sortedPendingItems: [Item]? = nil,
        sortedCompletedItems: [Item] = [],
        showCompleted: Bool = false,
        completedFooter: String? = nil,
        rowId: @escaping (_ item: Item) -> String = { $0.stableId.uuidString },
        tint: @escaping (_: Item) -> Color,
        toggleConfig: @escaping (_: Item) -> ToggleConfig? = { _ in nil },
        @ViewBuilder leftAdornment: @escaping (_: Item) -> LeftAdornment,
        @ViewBuilder rightAdornment: @escaping (_: Item) -> RightAdornment,
        @ViewBuilder bottomAdornment: @escaping (_: Item) -> BottomAdornment,
        scrollProxy: ScrollViewProxy,
        namespace: Namespace.ID? = nil,
        settings: Settings
    ) {
        self.sortedItems = sortedItems
        self.itemsLabel = itemsLabel
        self.floatingInfo = floatingInfo
        self.createItem = createItem
        self.moveItem = moveItem
        self.deleteItem = deleteItem
        self.handleTitleChange = handleTitleChange
        self.sortedPendingItems = sortedPendingItems ?? sortedItems
        self.sortedCompletedItems = sortedCompletedItems
        self.showCompleted = showCompleted
        self.completedFooter = completedFooter
        self.rowId = rowId
        self.tint = tint
        self.toggleConfig = toggleConfig
        self.leftAdornment = leftAdornment
        self.rightAdornment = rightAdornment
        self.bottomAdornment = bottomAdornment
        self.scrollProxy = scrollProxy
        self.namespace = namespace
        self.settings = settings
    }

    @Environment(\.scenePhase) private var appPhase
    @EnvironmentObject private var listEngine: ListEngine<Item>

    private var emptyPendingLabel: LocalizedStringKey {
        "No \(!sortedCompletedItems.isEmpty ? "more " : "")\(itemsLabel.lowercased())"
    }

    private var completedHeader: String {
        "Completed \(itemsLabel)"
    }

    private var emptyCompletedLabel: LocalizedStringKey {
        "No completed \(itemsLabel.lowercased())"
    }

    // MARK: - Body

    var body: some View {
        List {
            pendingList
            completedList
        }
        .animateUserAction(from: sortedItems.count)
        .listStyle(.plain)
        .environment(\.defaultMinListRowHeight, 0)
        .background(Color.appBackground.edgesIgnoringSafeArea(.all))
        .safeAreaInset(edge: .top) {
            floatingInfo
                .padding(.horizontal)
                .padding(.bottom, -(ListLayout.SEPARATOR_HEIGHT / 2))
        }
        .overlay {
            if sortedPendingItems.isEmpty, !showCompleted {
                EmptyLabel(emptyPendingLabel)
                    .transition(.opacity)
            }
        }

        // MARK: Blur the textfield when the list disappears (deletes empty items).

        .onDisappear {
            listEngine.focusedId = nil
        }

        // MARK: Blur the textfield when the app exits focus (deletes empty items).

        .onChange(of: appPhase) { _, phase in
            if phase == .inactive {
                listEngine.focusedId = nil
            }
        }

        // MARK: Slide to checked items when the user marks them visible.

        .withScrollTrigger(
            scrollProxy: scrollProxy,
            trigger: showCompleted,
            id: ListIds.COMPLETED_ITEMS,
            disabled: !showCompleted
        )
    }

    // MARK: - View Builders

    private var pendingList: some View {
        Section {
            SeparatorView(settings: settings) {
                attemptCreateItem(at: 0)
            }
            .listRowInsets(EdgeInsets())
            .discreetListItem()

            ForEach(
                Array(sortedPendingItems.enumerated()),
                id: \.element.stableId
            ) { index, item in
                RowView(
                    item: item,
                    index: index,
                    tint: tint(item),
                    customToggleConfig: toggleConfig(item),
                    leftAdornment: leftAdornment(item),
                    rightAdornment: rightAdornment(item),
                    bottomAdornment: bottomAdornment(item),
                    showCompleted: showCompleted,
                    namespace: namespace,
                    settings: settings,
                    createItem: attemptCreateItem,
                    deleteItem: deleteItem,
                    onTitleChange: handleTitleChange
                )
                .id(rowId(item))
            }
            .onMove(perform: handleRowMove)

            SeparatorView(settings: settings) {
                attemptCreateItem(at: sortedPendingItems.count)
            }
            .id(ListIds.PENDING_ITEMS)
            .listRowInsets(EdgeInsets())
            .discreetListItem()

            if sortedPendingItems.isEmpty && showCompleted {
                EmptyLabel(emptyPendingLabel)
                    .transition(.opacity)
                    .frame(maxWidth: .infinity)
                    .frame(height: ListLayout.EMPTY_LABEL_HEIGHT)
                    .discreetListItem()
            }
        }
        .listSectionSeparator(.hidden)
        .listSectionMargins(.top, 0)
    }

    @ViewBuilder
    private var completedList: some View {
        if showCompleted {
            Section {
                ForEach(
                    Array(sortedCompletedItems.enumerated()),
                    id: \.element.stableId
                ) { index, item in
                    RowView(
                        item: item,
                        index: index,
                        toggleOnly: true,
                        tint: tint(item),
                        customToggleConfig: toggleConfig(item),
                        leftAdornment: leftAdornment(item),
                        rightAdornment: rightAdornment(item),
                        bottomAdornment: bottomAdornment(item),
                        showCompleted: showCompleted,
                        settings: settings
                    )
                }

                if sortedCompletedItems.isEmpty {
                    EmptyLabel(emptyCompletedLabel)
                        .transition(.opacity)
                        .frame(maxWidth: .infinity)
                        .frame(height: ListLayout.EMPTY_LABEL_HEIGHT)
                        .discreetListItem()
                }
            } header: {
                Text(completedHeader)
            } footer: {
                if let completedFooter, !sortedCompletedItems.isEmpty {
                    Text(completedFooter)
                        .font(.footnote)
                        .foregroundStyle(Color.secondary)
                }
            }
            .id(ListIds.COMPLETED_ITEMS)
            .discreetListItem()
        }
    }

    // MARK: - Functions

    private func handleRowMove(
        from sources: IndexSet,
        to destination: Int
    ) {
        guard let source = sources.first, source != destination else { return }

        let insertionIndex = getInsertionIndex(
            pendingIndex: destination,
            sortedPendingItems: sortedPendingItems,
            sortedItems: sortedItems
        )

        moveItem(source, insertionIndex)
    }

    private func attemptCreateItem(at index: Int) {
        guard canCreateItem(at: index, in: sortedPendingItems) else {
            return
        }

        createItem(
            getInsertionIndex(
                pendingIndex: index,
                sortedPendingItems: sortedPendingItems,
                sortedItems: sortedItems
            )
        )
    }
}
