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
    @Bindable var item: Item
    let tint: (_ item: Item) -> Color
    let showChecked: Bool
    let showUpperDivider: Bool
    let toolbarIcons: [String]
    let tapToolbar: ((String, Item) -> Void)?
    let leftAdornment: ((_ item: Item) -> LeftAdornment)?
    let rightAdornment: ((_ item: Item) -> RightAdornment)?
    let bottomAdornment: ((_ item: Item) -> BottomAdornment)?
    let namespace: Namespace.ID?
    let customToggleConfig: RowToggleConfig<Item>?
    let onCreateItem:
        (_ baseId: UUID?, _ offset: Int) ->
            Void
    let onTitleChange: (_ item: Item) -> Void
    let isItemChecked: ((_ item: Item) -> Bool)?

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var listManager: ListManager<Item>

    // Will be updated dynamically within the TextfieldView.
    @State private var height: CGFloat = 0

    @State private var debounceTask: Task<Void, Never>? = nil

    private var isFocused: Bool {
        listManager.focusedId == item.stableId
    }

    private var tintColor: Color {
        tint(item)
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

        return isItemChecked?(item) == true || item.isChecked
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
            tint: tintColor,
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
                showUpperDivider: showUpperDivider,
                onCreateItem: {
                    guard !listManager.isSelectMode else {
                        listManager.toggleItem(item)
                        return
                    }

                    onCreateItem(item.stableId, 0)
                }
            )

            HStack(alignment: .top, spacing: 4) {

                // Left Adornment
                if let leftAdornment = leftAdornment {
                    leftAdornment(item)
                        .opacity(opacity)
                        .frame(
                            height: RowConstants.horizontalAdornmentHeight,
                            alignment: .center
                        )
                }

                // Title
                ZStack(alignment: .leading) {
                    titleText
                    editableField
                }
                .padding(.vertical, RowConstants.verticalTextPadding)
                .opacity(opacity)

                // Right Adornment
                if let rightAdornment = rightAdornment {
                    rightAdornment(item)
                        .opacity(opacity)
                        .frame(
                            height: RowConstants.horizontalAdornmentHeight,
                            alignment: .center
                        )
                }

            }
            .frame(minHeight: RowConstants.horizontalAdornmentHeight)

            // Bottom Adornment
            if let bottomAdornment {
                bottomAdornment(item)
                    .opacity(opacity)
            }

            // Lower Item Trigger
            NewRowTriggerView(
                showLowerDivider: true,
                onCreateItem: {
                    guard !listManager.isSelectMode else {
                        listManager.toggleItem(item)
                        return
                    }

                    onCreateItem(item.stableId, 1)
                }
            )
        }
    }

    // Static Text
    private var titleText: some View {
        Text(item.title)
            .opacity(isFocused ? 0 : 1)
            .font(.system(size: UIConstants.listItemFontSize))
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
            accentColor: tintColor,
            onTapToolbar: { iconName in
                tapToolbar?(iconName, item)
            },
            onEnter: {
                if !item.title.isEmpty {
                    onCreateItem(item.stableId, 1)
                } else {
                    listManager.focusedId = nil
                }
            }
        )
        .tint(tintColor)
        .frame(height: height)
        .opacity(isFocused ? 1 : 0)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)

        // Debounce the external save each time the text changes.
        .onChange(of: item.title) { _, newTitle in
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
                    onTitleChange(item)
                }
            }
        }
    }

}
