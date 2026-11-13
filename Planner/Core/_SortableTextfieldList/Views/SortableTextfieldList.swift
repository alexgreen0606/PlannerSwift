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
    private let onCommitItem: ((Item) -> Void)?
    private let onAdornmentClick: ((Item) -> Void)?

    private let sortedPendingItems: [Item]

    private let sortedCompletedItems: [Item]
    private let showCompleted: Bool
    private let completedFooter: String?

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
        onCommitItem: ((Item) -> Void)? = nil,
        onAdornmentClick: ((Item) -> Void)? = nil,
        sortedPendingItems: [Item]? = nil,
        sortedCompletedItems: [Item] = [],
        showCompleted: Bool = false,
        completedFooter: String? = nil,
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
        self.tint = tint
        self.toggleConfig = toggleConfig
        self.leftAdornment = leftAdornment
        self.rightAdornment = rightAdornment
        self.bottomAdornment = bottomAdornment
        self.scrollProxy = scrollProxy
        self.namespace = namespace
        self.settings = settings
    }
    
    @Environment(\.scenePhase) private var scenePhase
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
        ZStack {
            if #available(iOS 27, *) {
                ScrollView {
                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                        pendingSection
                        completedSection
                    }
                    .reorderContainer(
                        for: Item.self,
                        itemID: \.stableId,
                        move: handleRowReorder
                    )
                }
            } else {
                List {
                    pendingSection
                        .discreetListItem()
                        .listSectionSeparator(.hidden)
                        .listSectionMargins(.top, 0)

                    completedSection
                        .discreetListItem()
                }
                .listStyle(.plain)
                .environment(\.defaultMinListRowHeight, 0)
                .background(Color.appBackground.edgesIgnoringSafeArea(.all))
            }
        }
        .safeAreaInset(edge: .top) {
            floatingInfoView
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
        .onChange(of: scenePhase) { _, _ in
            if scenePhase == .inactive {
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

    @ViewBuilder
    private var floatingInfoView: some View {
        floatingInfo
            .padding(.horizontal)
            .padding(.top, 4)
            .padding(.bottom, -(ListLayout.SEPARATOR_HEIGHT / 2))
    }

    @ViewBuilder
    private var pendingSection: some View {
        Section {
            SeparatorView(settings: settings) {
                if !listEngine.isSelectMode {
                    attemptCreateItem(at: 0)
                }
            }
            .listRowInsets(EdgeInsets())
            .discreetListItem()

            let items = ForEach(sortedPendingItems, id: \.stableId) { item in
                RowView(
                    item: item,
                    index: indexOf(item, in: sortedPendingItems),
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
            }

            if #available(iOS 27, *) {
                items.reorderable()
            } else {
                items.onMove(perform: handleRowMove)
            }

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
            if #available(iOS 27, *) {
                pendingHeader
                    .padding(.horizontal)
            } else {
                pendingHeader
                    .listRowInsets(.vertical, 0)
            }
        } footer: {
            if #available(iOS 27, *), showCompleted {
                Color.clear.frame(height: 32)
            }
        }
    }

    @ViewBuilder
    private var completedSection: some View {
        if showCompleted {
            Section {
                ForEach(sortedCompletedItems, id: \.stableId) { item in
                    RowView(
                        item: item,
                        index: indexOf(item, in: sortedCompletedItems),
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

                SeparatorView(settings: settings)

                if sortedCompletedItems.isEmpty {
                    EmptyLabel(emptyCompletedLabel)
                        .transition(.opacity)
                        .frame(maxWidth: .infinity)
                        .frame(height: ListLayout.EMPTY_LABEL_HEIGHT)
                        .discreetListItem()
                }
            } header: {
                if #available(iOS 27, *) {
                    completedHeaderView
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                } else {
                    completedHeaderView
                }
            } footer: {
                if let completedFooter, !sortedCompletedItems.isEmpty {
                    Text(completedFooter)
                        .font(.footnote)
                        .foregroundStyle(Color.secondary)
                }
            }
            .id(ListIds.COMPLETED_ITEMS)
        }
    }

    @ViewBuilder
    private var completedHeaderView: some View {
        VStack(alignment: .leading) {
            Text(completedHeaderText)
                .font(
                    .system(
                        size: 16,
                        weight: .bold,
                        design: .rounded
                    )
                )
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)

            completedHeader
        }
    }

    // MARK: - Functions

    private func handleRowMove(
        from sources: IndexSet,
        to destination: Int
    ) {
        guard let sourceIndex = sources.first, sourceIndex != destination else {
            return
        }

        let insertionIndex = getInsertionIndex(
            pendingIndex: destination,
            sortedPendingItems: sortedPendingItems,
            sortedItems: sortedItems
        )

        moveItem(sourceIndex, insertionIndex)
    }

    @available(iOS 27, *)
    private func handleRowReorder(
        _ difference: ReorderDifference<
            UUID,
            ReorderableSingleCollectionIdentifier
        >
    ) {
        guard
            let sourceIndex = sortedPendingItems.firstIndex(
                where: { $0.stableId == difference.sources[0] }
            )
        else { return }

        let destinationIndex: Int

        switch difference.destination.position {
        case .before(let value):
            guard
                let index = sortedPendingItems.firstIndex(where: {
                    $0.stableId == value
                })
            else { return }

            destinationIndex = index

        case .end:
            destinationIndex = sortedPendingItems.endIndex
        }

        let insertionIndex = getInsertionIndex(
            pendingIndex: destinationIndex,
            sortedPendingItems: sortedPendingItems,
            sortedItems: sortedItems
        )

        moveItem(sourceIndex, insertionIndex)
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

    private func indexOf(_ item: Item, in items: [Item]) -> Int {
        return items.firstIndex(
            where: { $0.stableId == item.stableId }
        ) ?? 0
    }
}
