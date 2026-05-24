//
//  Row.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import SwiftData
import SwiftUI

// Clean

struct RowView<
    Item: ListItem,
    LeftAdornment: View,
    RightAdornment: View,
    BottomAdornment: View
>: View {
    @Bindable private var item: Item
    private let index: Int
    private let showChecked: Bool
    private let isUpperItem: Bool
    private let tint: Color
    private let leftAdornment: LeftAdornment
    private let rightAdornment: RightAdornment
    private let bottomAdornment: BottomAdornment
    private let toggleOnlyMode: Bool
    private let toolbarSystemImageNames: [String]
    private let customToggleConfig: ToggleConfig?
    private let namespace: Namespace.ID?
    private let createItem: ((_: Int) -> Void)?
    private let deleteItem: ((_: Item) -> Void)?
    private let onToolbarTap: ((String, Item) -> Void)?
    private let onTitleChange: ((_: Item) -> Void)?

    init(
        item: Item,
        index: Int,
        showChecked: Bool,
        isUpperItem: Bool,
        tint: Color,
        leftAdornment: LeftAdornment,
        rightAdornment: RightAdornment,
        bottomAdornment: BottomAdornment,
        toggleOnlyMode: Bool = false,
        toolbarSystemImageNames: [String]? = [],
        customToggleConfig: ToggleConfig? = nil,
        namespace: Namespace.ID? = nil,
        createItem: ((_: Int) -> Void)? = nil,
        deleteItem: ((_: Item) -> Void)? = nil,
        onToolbarTap: ((String, Item) -> Void)? = nil,
        onTitleChange: ((_: Item) -> Void)? = nil
    ) {
        self.item = item
        self.index = index
        self.showChecked = showChecked
        self.isUpperItem = isUpperItem
        self.tint = tint
        self.leftAdornment = leftAdornment
        self.rightAdornment = rightAdornment
        self.bottomAdornment = bottomAdornment
        self.toggleOnlyMode = toggleOnlyMode
        self.toolbarSystemImageNames = toolbarSystemImageNames ?? []
        self.createItem = createItem
        self.deleteItem = deleteItem
        self.customToggleConfig = customToggleConfig
        self.namespace = namespace
        self.onToolbarTap = onToolbarTap
        self.onTitleChange = onTitleChange
    }

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var listEngine: ListEngine<Item>

    /// Will be updated dynamically within the TextfieldView.
    @State private var height: CGFloat = 0

    @State private var titleChangeHandlerTask: Task<Void, Never>? = nil

    private var isFocused: Bool {
        listEngine.focusedId == item.stableId
    }

    private var isChecked: Bool {
        if listEngine.isSelectMode {
            return listEngine.selectedItemIds.contains(item.stableId)
        }

        return item.isCompleted
    }

    private var opacity: Double {
        if !showChecked, listEngine.fadingItemIds.contains(item.stableId) {
            return listEngine.fadingOpacity
        }
        return 1
    }

    var body: some View {
        let row =
            row
                .frame(maxWidth: .infinity, alignment: .top)
                .listRowInsets(EdgeInsets())
                .discreetListItem()
                .padding(.horizontal)
                // Trigger focus for new items.
                .onAppear {
                    if listEngine.pendingFocusId == item.stableId {
                        listEngine.pendingFocusId = nil
                        listEngine.focusedId = item.stableId
                    }
                }

        if let namespace {
            row
                .matchedTransitionSource(id: item.stableId.uuidString, in: namespace)
        } else {
            row
        }
    }

    // MARK: - View Builders

    private var row: some View {
        HStack(alignment: .top, spacing: 12) {
            toggle
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var toggle: some View {
        ListItemToggleView(
            item: item,
            color: tint,
            opacity: opacity,
            customToggleConfig: customToggleConfig
        )
        .frame(height: ListLayout.TOGGLE_HEIGHT, alignment: .center)
    }

    private var content: some View {
        VStack(spacing: 0) {
            SeparatorView(
                showUpperDivider: isUpperItem,
                opacity: opacity,
                onTap: {
                    if listEngine.isSelectMode || toggleOnlyMode {
                        listEngine.toggleItem(item)
                        return
                    }

                    createItem?(index)
                }
            )

            HStack(alignment: .top, spacing: 4) {
                leftAdornment
                    .opacity(opacity)
                    .frame(
                        height: ListLayout.ADORNMENT_HEIGHT,
                        alignment: .center
                    )

                ZStack(alignment: .leading) {
                    text
                    textfield
                }
                .padding(.vertical, ListLayout.VERTICAL_TEXT_PADDING)
                .opacity(opacity)

                rightAdornment
                    .opacity(opacity)
                    .frame(
                        height: ListLayout.ADORNMENT_HEIGHT,
                        alignment: .center
                    )
            }
            .frame(minHeight: ListLayout.ADORNMENT_HEIGHT)

            bottomAdornment
                .opacity(opacity)

            SeparatorView(
                showLowerDivider: true,
                opacity: opacity,
                onTap: {
                    if listEngine.isSelectMode || toggleOnlyMode {
                        listEngine.toggleItem(item)
                        return
                    }

                    createItem?(index + 1)
                }
            )
        }
    }

    private var text: some View {
        Text(item.title)
            .opacity(isFocused ? 0 : 1)
            .font(.system(size: ListLayout.FONT_SIZE))
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                if listEngine.isSelectMode || toggleOnlyMode {
                    listEngine.toggleItem(item)
                    return
                }

                if !isChecked {
                    listEngine.focusedId = item.stableId
                }
            }
    }

    private var textfield: some View {
        TextfieldView(
            focusedId: $listEngine.focusedId,
            text: $item.title,
            height: $height,
            itemId: item.stableId,
            accentColor: tint,
            toolbarSystemImageNames: toolbarSystemImageNames,
            onTapToolbar: { iconName in
                onToolbarTap?(iconName, item)
            },
            onEnter: {
                if !item.title.isEmpty {
                    createItem?(index + 1)
                } else {
                    // Triggers a deletion of the item in the below handler.
                    listEngine.focusedId = nil
                }
            }
        )
        .tint(tint)
        .frame(height: height)
        .opacity(isFocused ? 1 : 0)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        // Debounce the external save each time the text changes.
        .onChange(of: item.title) { _, _ in
            guard let onTitleChange else { return }

            titleChangeHandlerTask?.cancel()

            titleChangeHandlerTask = Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
                guard !Task.isCancelled else { return }

                onTitleChange(item)
            }
        }

        // Handle focus side effects.
        .onChange(of: isFocused) { wasFocused, isFocused in
            if wasFocused, !isFocused {
                titleChangeHandlerTask?.cancel()

                let trimmed = item.title.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

                if trimmed.isEmpty {
                    if listEngine.protectedId != item.stableId {
                        if let deleteItem {
                            deleteItem(item)
                        } else {
                            modelContext.safeDelete(item)
                        }
                    }
                } else {
                    item.title = trimmed
                    onTitleChange?(item)
                }
            }
        }
    }
}
