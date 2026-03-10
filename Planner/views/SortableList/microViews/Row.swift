//
//  Row.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import SwiftData
import SwiftUI

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
    private let toolbarIcons: [String]
    private let customToggleConfig: RowToggleConfig<Item>?
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
        toolbarIcons: [String]? = [],
        customToggleConfig: RowToggleConfig<Item>? = nil,
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
        self.toolbarIcons = toolbarIcons ?? []
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

    @State private var debounceTask: Task<Void, Never>? = nil

    private var isFocused: Bool {
        listManager.focusedId == item.stableId
    }

    private var opacity: Double {
        guard !showChecked else { return 1 }

        let isPending = listManager.fadingItemIds.contains(item.stableId)

        return isPending ? listManager.fadingOpacity : 1
    }

    private var isChecked: Bool {
        if listManager.isSelectMode {
            return listManager.selectedItemIds.contains(item.stableId)
        }

        return item.isChecked
    }

    var body: some View {
        let row =
            rowContent
            .frame(maxWidth: .infinity, alignment: .top)
            .listRowInsets(EdgeInsets())
            .discreetListItem()
            .padding(.horizontal)

            // Trigger focus on render for new items.
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

    // Row Content
    private var rowContent: some View {
        HStack(alignment: .top, spacing: 12) {
            toggle
            textStack
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // Item Toggle
    private var toggle: some View {
        RowToggleView(
            item: item,
            tint: tint,
            isChecked: isChecked,
            opacity: opacity,
            customIconConfig: customToggleConfig
        )
        .frame(height: RowConstants.toggleHeight, alignment: .center)
    }

    // Item Text
    private var textStack: some View {
        VStack(spacing: 0) {

            // Upper Item Trigger
            NewRowTriggerView(
                showUpperDivider: isUpperItem,
                onCreateItem: {
                    guard !listManager.isSelectMode else {
                        listManager.toggleItem(item)
                        return
                    }

                    createItem?(item.stableId, 0)
                }
            )

            HStack(alignment: .top, spacing: 4) {

                // Left Adornment
                    leftAdornment
                        .opacity(opacity)
                        .frame(
                            height: RowConstants.horizontalAdornmentHeight,
                            alignment: .center
                        )

                // Title
                ZStack(alignment: .leading) {
                    titleText
                    editableField
                }
                .padding(.vertical, RowConstants.verticalTextPadding)
                .opacity(opacity)

                // Right Adornment
                rightAdornment
                    .opacity(opacity)
                        .frame(
                            height: RowConstants.horizontalAdornmentHeight,
                            alignment: .center
                        )
                
            }
            .frame(minHeight: RowConstants.horizontalAdornmentHeight)

            // Bottom Adornment
                bottomAdornment
                    .opacity(opacity)

            // Lower Item Trigger
            NewRowTriggerView(
                showLowerDivider: true,
                onCreateItem: {
                    guard !listManager.isSelectMode else {
                        listManager.toggleItem(item)
                        return
                    }

                    createItem?(item.stableId, 1)
                }
            )
        }
    }

    // Static Text
    private var titleText: some View {
        Text(item.title)
            .opacity(isFocused ? 0 : 1)
            .font(.system(size: UiConstants.listItemFontSize))
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                guard !listManager.isSelectMode else {
                    listManager.toggleItem(item)
                    return
                }

                if !isChecked && !item.isChecked {
                    listManager.focusedId = item.stableId
                }
            }
    }

    // Textfield
    private var editableField: some View {
        RowTextfieldView(
            itemId: item.stableId,
            focusedId: $listManager.focusedId,
            text: $item.title,
            height: $height,
            toolbarIcons: toolbarIcons,
            accentColor: tint,
            onTapToolbar: { iconName in
                onToolbarTap?(iconName, item)
            },
            onEnter: {
                if !item.title.isEmpty {
                    createItem?(item.stableId, 1)
                } else {
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
        .id("\(item.stableId)-\(isFocused)")

        // Debounce the external save each time the text changes.
        .onChange(of: item.title) { _, newTitle in
            guard let onTitleChange else { return }
            
            debounceTask?.cancel()
            debounceTask = Task {
                try? await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second
                guard !Task.isCancelled else { return }
                onTitleChange(item)
            }
        }

        // Handle focus side effects.
        .onChange(of: isFocused) { wasFocused, isFocused in
            if wasFocused, !isFocused {
                debounceTask?.cancel()

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
            }
        }
    }

}
