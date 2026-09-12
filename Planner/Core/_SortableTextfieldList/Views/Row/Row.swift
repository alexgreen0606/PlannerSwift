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
    private let onCommit: ((_: Item) -> Void)?

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
        modelContext: ModelContext,
        createItem: ((_: Int) -> Void)? = nil,
        deleteItem: ((_: Item) -> Void)? = nil,
        onCommit: ((_: Item) -> Void)? = nil
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
        self.onCommit = onCommit

        self._editorSession = StateObject(
            wrappedValue: EditorSession(
                item: item,
                deleteItem: { item in
                    if let deleteItem {
                        deleteItem(item)
                    } else {
                        modelContext.safeDelete(item)
                    }
                },
                onCommit: onCommit
            )
        )
    }

    @EnvironmentObject private var listEngine: ListEngine<Item>

    @StateObject private var editorSession: EditorSession<Item>

    private var isItemFocused: Bool {
        listEngine.isItemFocused(item)
    }

    private var isToggleable: Bool {
        toggleOnly || listEngine.isSelectMode
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
            .allowsHitTesting(!isToggleable)
            .contentShape(Rectangle())
            .onTapGesture {
                guard isToggleable else { return }
                listEngine.toggleItem(item)
            }

            // MARK: Trigger focus for new items.

            .onAppear {
                if listEngine.pendingFocusId == item.stableId {
                    listEngine.pendingFocusId = nil
                    listEngine.beginEditing(editorSession)
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
                    safeCreateItem(at: index)
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
                    safeCreateItem(at: index + 1)
                }
            )
        }
    }

    @ViewBuilder
    private var titleView: some View {
        ZStack {
            if isItemFocused || listEngine.wasItemFocused(item) {
                titleTextfield
            } else {
                staticTitle
            }
        }
    }

    private var titleTextfield: some View {
        TextfieldView(
            text: $editorSession.title,
            height: $editorSession.height,
            tint: tint,
            shouldResign: !listEngine.isFocused,
            isFocused: isItemFocused,
            onEndEditing: {
                listEngine.handleEndEditing(editorSession)
            },
            onEnter: {
                if !editorSession.hasEmptyTitle {
                    safeCreateItem(at: index + 1)
                } else {
                    listEngine.blur()
                }
            }
        )
        .tint(tint)
        .frame(height: editorSession.height)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var staticTitle: some View {
        Text(editorSession.title)
            .font(.system(size: ListLayout.FONT_SIZE))
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                listEngine.beginEditing(editorSession)
            }
    }

    // MARK: - Functions

    private func safeCreateItem(at index: Int) {
        // TODO: need to ensure this doesn't create if the onCommit makes the title empty again.
        // actually it can, but the item must be deleted.
        
        if let createItem {
            listEngine.commitFocusedItemTitle()
            createItem(index)
        }
    }
}
