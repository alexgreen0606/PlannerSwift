//
//  Row.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import SwiftData
import SwiftUI

// Clean

enum RowConstants {
    static let horizontalAdornmentHeight: CGFloat = 32
    static let verticalTextPadding: CGFloat = 6
    static let separatorHeight: CGFloat = 10
    static let toggleHeight: CGFloat = 54
}

struct RowView<
    Item: ListItem,
    LeftAdornment: View,
    RightAdornment: View,
    BottomAdornment: View
>: View {
    @Bindable private var item: Item
    private let showChecked: Bool
    private let isUpperItem: Bool
    private let tint: Color
    private let leftAdornment: LeftAdornment
    private let rightAdornment: RightAdornment
    private let bottomAdornment: BottomAdornment
    private let toolbarSystemImageNames: [String]
    private let customToggleConfig: ToggleConfig<Item>?
    private let namespace: Namespace.ID?
    private let createItem: ((_ baseId: UUID?, _ offset: Int) -> Void)?
    private let onToolbarTap: ((String, Item) -> Void)?
    private let onTitleChange: ((_ item: Item) -> Void)?

    init(
        item: Item,
        showChecked: Bool,
        isUpperItem: Bool,
        tint: Color,
        leftAdornment: LeftAdornment,
        rightAdornment: RightAdornment,
        bottomAdornment: BottomAdornment,
        toolbarSystemImageNames: [String]? = [],
        customToggleConfig: ToggleConfig<Item>? = nil,
        namespace: Namespace.ID? = nil,
        createItem: ((_: UUID?, _: Int) -> Void)? = nil,
        onToolbarTap: ((String, Item) -> Void)? = nil,
        onTitleChange: ((_: Item) -> Void)? = nil
    ) {
        self.item = item
        self.showChecked = showChecked
        self.isUpperItem = isUpperItem
        self.tint = tint
        self.leftAdornment = leftAdornment
        self.rightAdornment = rightAdornment
        self.bottomAdornment = bottomAdornment
        self.toolbarSystemImageNames = toolbarSystemImageNames ?? []
        self.createItem = createItem
        self.customToggleConfig = customToggleConfig
        self.namespace = namespace
        self.onToolbarTap = onToolbarTap
        self.onTitleChange = onTitleChange
    }

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var listManager: ListManager<Item>

    // Will be updated dynamically within the TextfieldView.
    @State private var height: CGFloat = 0

    @State private var textfieldId = UUID()
    @State private var titleChangeHandlerTask: Task<Void, Never>? = nil

    private var isFocused: Bool {
        listManager.focusedId == item.stableId
    }

    private var isChecked: Bool {
        if listManager.isSelectMode {
            return listManager.selectedItemIds.contains(item.stableId)
        }
        return item.isChecked
    }

    private var opacity: Double {
        if !showChecked, listManager.fadingItemIds.contains(item.stableId) {
            return listManager.fadingOpacity
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
                if listManager.pendingFocusId == item.stableId {
                    listManager.pendingFocusId = nil
                    listManager.focusedId = item.stableId
                }
            }

        if let namespace {
            row
                .matchedTransitionSource(id: "\(item.stableId)", in: namespace)
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
            tint: tint,
            isChecked: isChecked,
            opacity: opacity,
            customToggleConfig: customToggleConfig
        )
        .frame(height: RowConstants.toggleHeight, alignment: .center)
    }

    private var content: some View {
        VStack(spacing: 0) {

            SeparatorView(
                showUpperDivider: isUpperItem,
                onTap: {
                    if listManager.isSelectMode {
                        listManager.toggleItem(item)
                        return
                    }

                    createItem?(item.stableId, 0)
                }
            )

            HStack(alignment: .top, spacing: 4) {

                leftAdornment
                    .opacity(opacity)
                    .frame(
                        height: RowConstants.horizontalAdornmentHeight,
                        alignment: .center
                    )

                ZStack(alignment: .leading) {
                    text
                    textfield
                }
                .padding(.vertical, RowConstants.verticalTextPadding)
                .opacity(opacity)

                rightAdornment
                    .opacity(opacity)
                    .frame(
                        height: RowConstants.horizontalAdornmentHeight,
                        alignment: .center
                    )

            }
            .frame(minHeight: RowConstants.horizontalAdornmentHeight)

            bottomAdornment
                .opacity(opacity)

            SeparatorView(
                showLowerDivider: true,
                onTap: {
                    if listManager.isSelectMode {
                        listManager.toggleItem(item)
                        return
                    }

                    createItem?(item.stableId, 1)
                }
            )
        }
    }

    private var text: some View {
        Text(item.title)
            .opacity(isFocused ? 0 : 1)
            .font(.system(size: UiConstants.listItemFontSize))
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                if listManager.isSelectMode {
                    listManager.toggleItem(item)
                    return
                }

                if !isChecked {
                    listManager.focusedId = item.stableId
                }
            }
    }

    private var textfield: some View {
        RowTextfieldView(
            focusedId: $listManager.focusedId,
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
                    createItem?(item.stableId, 1)
                } else {
                    // Triggers a deletion of the item in the below handler.
                    listManager.focusedId = nil
                }
            }
        )
        .tint(tint)
        .frame(height: height)
        .opacity(isFocused ? 1 : 0)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)

        // Note: This ensures that focused textfields have up-to-date snapshots of onCreateItem
        .id(textfieldId)

        // Debounce the external save each time the text changes.
        .onChange(of: item.title) { _, newTitle in
            guard let onTitleChange else { return }

            titleChangeHandlerTask?.cancel()

            titleChangeHandlerTask = Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second
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
                    if listManager.protectedId != item.stableId {
                        Task { @MainActor in
                            modelContext.delete(item)
                        }
                    }
                } else {
                    item.title = trimmed
                    onTitleChange?(item)
                }

            } else if isFocused, !wasFocused {
                // Re-render focused textfields so they get a fresh snapshot of onCreateItem.
                textfieldId = UUID()
            }
        }
    }

}
