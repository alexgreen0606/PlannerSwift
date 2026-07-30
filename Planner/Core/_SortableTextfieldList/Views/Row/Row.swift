//
//  Row.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import SwiftData
import SwiftUI

struct RowView<
    Item: ListItemDetails,
    LeftAdornment: View,
    RightAdornment: View,
    BottomAdornment: View
>: View {
    private let item: Item
    private let index: Int
    private let toggleOnly: Bool
    private let tint: Color
    private let customToggleConfig: ToggleConfig?
    private let leftAdornment: LeftAdornment
    private let rightAdornment: RightAdornment
    private let bottomAdornment: BottomAdornment

    private let showCompleted: Bool
    private let namespace: Namespace.ID?
    private let settings: Settings
    private let createItem: ((_: Int) -> Void)?
    private let deleteItem: ((_: Item) -> Void)?
    private let onTitleChange: ((_: Item) -> Void)?

    init(
        item: Item,
        index: Int,
        toggleOnly: Bool = false,
        tint: Color,
        customToggleConfig: ToggleConfig? = nil,
        leftAdornment: LeftAdornment,
        rightAdornment: RightAdornment,
        bottomAdornment: BottomAdornment,
        showCompleted: Bool,
        namespace: Namespace.ID? = nil,
        settings: Settings,
        createItem: ((_: Int) -> Void)? = nil,
        deleteItem: ((_: Item) -> Void)? = nil,
        onTitleChange: ((_: Item) -> Void)? = nil
    ) {
        self.item = item
        self.index = index
        self.toggleOnly = toggleOnly
        self.tint = tint
        self.customToggleConfig = customToggleConfig
        self.leftAdornment = leftAdornment
        self.rightAdornment = rightAdornment
        self.bottomAdornment = bottomAdornment
        self.showCompleted = showCompleted
        self.namespace = namespace
        self.settings = settings
        self.createItem = createItem
        self.deleteItem = deleteItem
        self.onTitleChange = onTitleChange

        self._title = State(initialValue: item.title)
    }

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var listEngine: ListEngine<Item>

    @State private var titleChangeHandlerTask: Task<Void, Never>? = nil

    @State private var title: String

    private var isFocused: Bool {
        listEngine.focusedId == item.stableId
    }

    private var isChecked: Bool {
        if listEngine.isSelectMode {
            return listEngine.selectedItemIds.contains(item.stableId)
        }

        return listEngine.isItemToggled(item)
    }

    private var opacity: Double {
        guard listEngine.fadingItemIds.contains(item.stableId), !showCompleted
        else {
            return 1
        }

        return listEngine.fadingOpacity
    }

    private var heightBinding: Binding<CGFloat> {
        Binding(
            get: { item.height },
            set: { item.height = $0 }
        )
    }

    // MARK: - Body

    var body: some View {
        let row =
            HStack(alignment: .top, spacing: 12) {
                toggle
                content
            }
            .listRowInsets(EdgeInsets())
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal)
            .discreetListItem()
            .allowsHitTesting(!toggleOnly && !listEngine.isSelectMode)
            .contentShape(Rectangle())
            .onTapGesture {
                guard toggleOnly || listEngine.isSelectMode else { return }
                listEngine.toggleItem(item)
            }

            // MARK: Trigger focus for new items.

            .onAppear {
                if listEngine.pendingFocusId == item.stableId {
                    listEngine.pendingFocusId = nil
                    listEngine.focusedId = item.stableId
                }
            }

            // MARK: Sync the state title with the item's title when it is changed from an external source.

            .task(id: item.title) {
                if title != item.title {
                    title = item.title
                }
            }

        if let namespace {
            row
                .matchedTransitionSource(
                    id: item.stableId.uuidString,
                    in: namespace
                )
        } else {
            row
        }
    }

    // MARK: - View Builders

    private var toggle: some View {
        ListItemToggleView(
            item: item,
            color: tint,
            opacity: opacity,
            customToggleConfig: customToggleConfig
        )
        .frame(height: ListLayout.TOGGLE_HEIGHT)
    }

    private var content: some View {
        VStack(spacing: 0) {
            SeparatorView(
                showUpperDivider: index == 0,
                opacity: opacity,
                settings: settings,
                onTap: {
                    if listEngine.isSelectMode || toggleOnly {
                        listEngine.toggleItem(item)
                        return
                    }

                    createItem?(index)
                }
            )

            HStack(alignment: .top, spacing: 8) {
                leftAdornment
                    .frame(height: ListLayout.ADORNMENT_HEIGHT)
                    .opacity(opacity)

                titleView
                    .padding(.vertical, ListLayout.VERTICAL_TEXT_PADDING)
                    .opacity(opacity)

                rightAdornment
                    .frame(height: ListLayout.ADORNMENT_HEIGHT)
                    .opacity(opacity)
            }
            .frame(minHeight: ListLayout.ADORNMENT_HEIGHT)

            bottomAdornment
                .opacity(opacity)

            SeparatorView(
                showLowerDivider: true,
                opacity: opacity,
                settings: settings,
                onTap: {
                    if listEngine.isSelectMode || toggleOnly {
                        listEngine.toggleItem(item)
                        return
                    }

                    createItem?(index + 1)
                }
            )
        }
    }

    @ViewBuilder
    private var titleView: some View {
        ZStack {
            if isFocused || listEngine.keyboardOwnerId == item.stableId {
                titleTextfield
            } else {
                staticTitle
            }
        }

        // MARK: Focus change handler.

        .onChange(of: isFocused) { wasFocused, isFocused in
            if wasFocused, !isFocused {
                titleChangeHandlerTask?.cancel()

                let trimmedTitle = title.trimmed

                if trimmedTitle.isEmpty {
                    // Item is blurred and has an empty title. Delete it.
                    if listEngine.protectedId != item.stableId {
                        // Note: Delay this so that the keyboard has time to animate closed before deletion.
                        DispatchQueue.main.async {
                            if let deleteItem {
                                deleteItem(item)
                            } else {
                                modelContext.safeDelete(item)
                            }
                        }
                    }
                } else {
                    item.title = trimmedTitle
                    onTitleChange?(item)
                }
            }
        }
    }

    private var titleTextfield: some View {
        TextfieldView(
            text: $title,
            height: heightBinding,
            focusedId: $listEngine.focusedId,
            keyboardOwnerId: $listEngine.keyboardOwnerId,
            stableId: item.stableId,
            tint: tint,
            onEnter: {
                item.title = title

                if !title.trimmed.isEmpty {
                    createItem?(index + 1)
                } else {
                    // Trigger a deletion of the item in the below handler.
                    listEngine.focusedId = nil
                }
            }
        )
        .tint(tint)
        .frame(height: item.height)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)

        // MARK: Debounce the title change handler (1 second delay).

        .onChange(of: title) { _, newTitle in
            guard let onTitleChange else { return }

            titleChangeHandlerTask?.cancel()

            titleChangeHandlerTask = Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { return }

                item.title = newTitle
                onTitleChange(item)
            }
        }
    }

    private var staticTitle: some View {
        Text(title)
            .font(.system(size: ListLayout.FONT_SIZE))
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                listEngine.focusedId = item.stableId
            }
    }
}
