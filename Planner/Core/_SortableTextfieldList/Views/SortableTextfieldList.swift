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
    PendingHeader: View,
    CompletedHeader: View,
    LeftAdornment: View,
    RightAdornment: View,
    BottomAdornment: View
>: View {
    private let sortedItems: [Item]
    private let itemsLabel: String
    private let floatingInfo: FloatingInfo?
    private let pendingHeader: PendingHeader?
    private let completedHeader: CompletedHeader?
    private let hideToggles: Bool
    private let createItem: (Int) -> Void
    private let moveItem: (Int, Int) -> Void
    private let deleteItem: ((Item) -> Void)?
    private let onCommitItem: ((Item, Item) -> Void)?
    private let onAdornmentClick: ((Item) -> Void)?

    private let sortedPendingItems: [Item]

    private let sortedCompletedItems: [Item]
    private let showCompleted: Bool
    private let completedFooter: String?

    private let rowId: (Item) -> String
    private let tint: (Item) -> Color
    private let toggleConfig: (Item) -> ToggleConfig?
    private let leftAdornment: (Item) -> LeftAdornment
    private let rightAdornment: (Item) -> RightAdornment
    private let bottomAdornment: (Item) -> BottomAdornment

    private let scrollProxy: ScrollViewProxy
    private let namespace: Namespace.ID?
    private let settings: Settings

    init(
        sortedItems: [Item],
        itemsLabel: String = "Items",
        floatingInfo: FloatingInfo? = EmptyView(),
        pendingHeader: PendingHeader? = EmptyView(),
        completedHeader: CompletedHeader? = EmptyView(),
        hideToggles: Bool = false,
        createItem: @escaping (Int) -> Void,
        moveItem: @escaping (Int, Int) -> Void,
        deleteItem: ((Item) -> Void)? = nil,
        onCommitItem: ((Item, Item) -> Void)? = nil,
        onAdornmentClick: ((Item) -> Void)? = nil,
        sortedPendingItems: [Item]? = nil,
        sortedCompletedItems: [Item] = [],
        showCompleted: Bool = false,
        completedFooter: String? = nil,
        rowId: @escaping (Item) -> String = { $0.stableId.uuidString },
        tint: @escaping (Item) -> Color,
        toggleConfig: @escaping (Item) -> ToggleConfig? = { _ in nil },
        @ViewBuilder leftAdornment: @escaping (Item) -> LeftAdornment,
        @ViewBuilder rightAdornment: @escaping (Item) -> RightAdornment,
        @ViewBuilder bottomAdornment: @escaping (Item) -> BottomAdornment,
        scrollProxy: ScrollViewProxy,
        namespace: Namespace.ID? = nil,
        settings: Settings
    ) {
        self.sortedItems = sortedItems
        self.itemsLabel = itemsLabel
        self.floatingInfo = floatingInfo
        self.pendingHeader = pendingHeader
        self.completedHeader = completedHeader
        self.hideToggles = hideToggles
        self.createItem = createItem
        self.moveItem = moveItem
        self.deleteItem = deleteItem
        self.onCommitItem = onCommitItem
        self.onAdornmentClick = onAdornmentClick
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
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var listEngine: ListEngine<Item>

    private var emptyPendingLabel: LocalizedStringKey {
        "No \(!sortedCompletedItems.isEmpty ? "more " : "")\(itemsLabel.lowercased())"
    }

    private var completedHeaderText: String {
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
        .listStyle(.plain)
        .environment(\.defaultMinListRowHeight, 0)
        .background(Color.appBackground.edgesIgnoringSafeArea(.all))
        .safeAreaInset(edge: .top) {
            floatingInfo
                .padding(.horizontal)
                .padding(
                    .top,
                    {
                        if #available(iOS 27, *) {
                            4
                        } else {
                            0
                        }
                    }()
                )
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
            listEngine.blur()
        }

        // MARK: Blur the textfield when the app exits focus (deletes empty items).

        .onChange(of: appPhase) { _, phase in
            if phase == .inactive {
                listEngine.blur()
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
                if !listEngine.isSelectMode {
                    attemptCreateItem(at: 0)
                }
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
                    hideToggle: hideToggles,
                    tint: tint(item),
                    customToggleConfig: toggleConfig(item),
                    leftAdornment: leftAdornment(item),
                    rightAdornment: rightAdornment(item),
                    bottomAdornment: bottomAdornment(item),
                    showCompleted: showCompleted,
                    namespace: namespace,
                    settings: settings,
                    modelContext: modelContext,
                    createItem: attemptCreateItem,
                    deleteItem: deleteItem,
                    onCommit: onCommitItem,
                    onAdornmentClick: onAdornmentClick
                )
                .id(rowId(item))
            }
            .onMove(perform: handleRowMove)

            SeparatorView(settings: settings) {
                if !listEngine.isSelectMode {
                    attemptCreateItem(at: sortedPendingItems.count)
                }
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
        } header: {
            pendingHeader
                .listRowInsets(.vertical, 0)
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
                        hideToggle: hideToggles,
                        tint: tint(item),
                        customToggleConfig: toggleConfig(item),
                        leftAdornment: leftAdornment(item),
                        rightAdornment: rightAdornment(item),
                        bottomAdornment: bottomAdornment(item),
                        showCompleted: showCompleted,
                        settings: settings,
                        modelContext: modelContext
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
                VStack(alignment: .leading) {
                    Text(completedHeaderText)
                    completedHeader
                }
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

        let insertionIndex = getInsertionIndex(
            pendingIndex: index,
            sortedPendingItems: sortedPendingItems,
            sortedItems: sortedItems
        )

        createItem(insertionIndex)
    }
}
