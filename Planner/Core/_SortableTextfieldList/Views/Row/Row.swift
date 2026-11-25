//
//  Row.swift
//  Planner
//
//  Created by Alex Green on 11/22/26.
//

import SwiftData
import SwiftUI

struct RowView<
    Item: ListItem,
    LeftAdornment: View,
    RightAdornment: View,
    BottomAdornment: View
>: View {
    private let item: Item
    private let index: Int
    private let toggleOnly: Bool
    private let hideToggle: Bool
    private let tint: Color
    private let customToggleConfig: ToggleConfig?
    private let leftAdornment: LeftAdornment
    private let rightAdornment: RightAdornment
    private let bottomAdornment: BottomAdornment

    private let showCompleted: Bool
    private let namespace: Namespace.ID?
    private let settings: Settings
    private let createItem: ((Int) -> Void)?
    private let onAdornmentClick: ((Item) -> Void)?

    // MARK: Pending Items
    init(
        item: Item,
        index: Int,
        hideToggle: Bool,
        tint: Color,
        customToggleConfig: ToggleConfig?,
        leftAdornment: LeftAdornment,
        rightAdornment: RightAdornment,
        bottomAdornment: BottomAdornment,
        showCompleted: Bool,
        namespace: Namespace.ID?,
        settings: Settings,
        listEngine: ListEngine<Item>,
        createItem: @escaping (Int) -> Void,
        deleteItem: @escaping (Item) -> Void,
        onCommit: ((Item) -> Void)?,
        onAdornmentClick: ((Item) -> Void)?
    ) {
        self.item = item
        self.index = index
        self.hideToggle = hideToggle
        self.tint = tint
        self.customToggleConfig = customToggleConfig
        self.leftAdornment = leftAdornment
        self.rightAdornment = rightAdornment
        self.bottomAdornment = bottomAdornment
        self.showCompleted = showCompleted
        self.namespace = namespace
        self.settings = settings
        self.createItem = createItem
        self.onAdornmentClick = onAdornmentClick

        self.toggleOnly = false

        self._listEngine = ObservedObject(wrappedValue: listEngine)
        self._editorSession = StateObject(
            wrappedValue: EditorSession(
                item: item,
                draft: listEngine.draft(for: item),
                deleteItem: { [weak listEngine] item in
                    listEngine?.discardDraft(for: item.id)
                    deleteItem(item)
                },
                onCommit: onCommit
            )
        )
    }

    // MARK: Completed Items
    init(
        item: Item,
        index: Int,
        hideToggle: Bool,
        tint: Color,
        customToggleConfig: ToggleConfig? = nil,
        leftAdornment: LeftAdornment,
        rightAdornment: RightAdornment,
        bottomAdornment: BottomAdornment,
        showCompleted: Bool,
        settings: Settings,
        listEngine: ListEngine<Item>
    ) {
        self.item = item
        self.index = index
        self.hideToggle = hideToggle
        self.tint = tint
        self.customToggleConfig = customToggleConfig
        self.leftAdornment = leftAdornment
        self.rightAdornment = rightAdornment
        self.bottomAdornment = bottomAdornment
        self.showCompleted = showCompleted
        self.settings = settings

        self.toggleOnly = true
        self.namespace = nil
        self.createItem = nil
        self.onAdornmentClick = nil

        self._listEngine = ObservedObject(wrappedValue: listEngine)
        self._editorSession = StateObject(
            wrappedValue: EditorSession(
                item: item,
                draft: listEngine.draft(for: item),
                deleteItem: { _ in }
            )
        )
    }

    @ObservedObject private var listEngine: ListEngine<Item>

    @StateObject private var editorSession: EditorSession<Item>

    private var isItemFocused: Bool {
        listEngine.isItemFocused(item)
    }

    private var isToggleable: Bool {
        toggleOnly || listEngine.isSelectMode
    }

    private var opacity: Double {
        guard listEngine.fadingItemIds.contains(item.id), !showCompleted
        else {
            return 1
        }

        return listEngine.fadingOpacity
    }

    // MARK: - Body

    var body: some View {
        let row =
            HStack(alignment: .top, spacing: 12) {
                if listEngine.isSelectMode || !hideToggle {
                    toggle
                }

                content
            }
            .id(item.id)
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
                if listEngine.pendingFocusId == item.id {
                    listEngine.pendingFocusId = nil
                    beginEditing()
                }
            }

        if let namespace {
            row
                .matchedTransitionSource(
                    id: item.id,
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
                    .frame(minHeight: ListLayout.ADORNMENT_HEIGHT)
                    .opacity(opacity)
                    .contentShape(Rectangle())
                    .onTapGesture(perform: handleAdornmentClick)

                VStack(alignment: .leading, spacing: 0) {

                    HStack(alignment: .top, spacing: 8) {
                        titleView
                            .padding(
                                .vertical,
                                ListLayout.VERTICAL_TEXT_PADDING
                            )
                            .opacity(opacity)

                        rightAdornment
                            .frame(minHeight: ListLayout.ADORNMENT_HEIGHT)
                            .opacity(opacity)
                            .contentShape(Rectangle())
                            .onTapGesture(perform: handleAdornmentClick)
                    }

                    VStack(spacing: 4) {
                        bottomAdornment

                        if !item.notes.trimmed.isEmpty {
                            Text(item.notes)
                                .font(.system(size: 12))
                                .foregroundStyle(Color.secondary)
                                .frame(
                                    maxWidth: .infinity,
                                    alignment: .leading
                                )
                        }
                    }
                    .opacity(opacity)
                    .contentShape(Rectangle())
                    .onTapGesture(perform: handleAdornmentClick)
                }

            }
            .frame(minHeight: ListLayout.ADORNMENT_HEIGHT)

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
            text: $editorSession.draft.title,
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
    }

    /// Displays the item's live title (not the draft) so that external changes
    /// are always reflected while the row is not being edited.
    private var staticTitle: some View {
        Text(item.title)
            .font(.system(size: ListLayout.FONT_SIZE))
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                if item.allowsEditing {
                    beginEditing()
                } else {
                    // Read-only items open their details instead of editing inline.
                    onAdornmentClick?(item)
                }
            }
    }

    // MARK: - Functions

    private func beginEditing() {
        guard item.allowsEditing else { return }
        listEngine.beginEditing(editorSession)
    }

    private func safeCreateItem(at index: Int) {
        if let createItem {
            listEngine.commitFocusedItemTitle()
            createItem(index)
        }
    }

    private func handleAdornmentClick() {
        if let onAdornmentClick {
            onAdornmentClick(item)
            return
        }

        beginEditing()
    }

}
