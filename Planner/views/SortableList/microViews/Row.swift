//
//  Row.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import SwiftData
import SwiftUI

enum RowConstants {
    static let horizontalAdornmentHeight: CGFloat = 34
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
        (_ baseId: PersistentIdentifier?, _ offset: Int) ->
            Void
    let onTitleChange: (_ item: Item) -> Void
    let isItemChecked: ((_ item: Item) -> Bool)?

    @Environment(\.scenePhase) private var appPhase
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var focusController: FocusController
    @EnvironmentObject private var listManager: ListManager<Item>

    // Will be updated dynamically within the TextfieldView.
    @State private var height: CGFloat = 0

    @State private var debounceTask: Task<Void, Never>? = nil

    private var isFocused: Bool {
        focusController.focusedId == item.id
    }
    
    private var isFocusedBinding: Binding<Bool> {
        Binding(
            get: {
                focusController.focusedId == item.id
            },
            set: { newValue in
                if newValue {
                    // TODO: fix this warning
                    focusController.focusedId = item.id
                } else if focusController.focusedId == item.id {
                    focusController.focusedId = nil
                }
            }
        )
    }

    private var tintColor: Color {
        tint(item)
    }

    private var opacity: Double {
        guard !showChecked else { return 1 }

        let isPending = listManager.fadingItemIds.contains(item.id)

        return isPending ? listManager.fadingOpacity : 1
    }

    private var isChecked: Bool {
        if listManager.isSelectMode {
            return listManager.selectedItemIds.contains(item.id)
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

            // Trigger focus on render for empty items (new items).
            .onAppear {
                if item.title.isEmpty, !isFocused {
                    focusController.focusedId = item.id
                }
            }

            // Blur the textfield when this item has been selected.
            .onChange(of: isChecked) { _, isChecked in
                if isChecked, isFocused {
                    focusController.focusedId = nil
                }
            }

            // Blur the textfield when the app exits focus.
            .onChange(of: appPhase) { _, phase in
                if phase == .inactive {
                    focusController.focusedId = nil
                }
            }

        if let namespace {
            row
                .matchedTransitionSource(id: "\(item.id)", in: namespace)
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
            NewRowTriggerView(
                showUpperDivider: showUpperDivider,
                onCreateItem: {
                    guard !listManager.isSelectMode else {
                        listManager.toggleItem(item)
                        return
                    }

                    onCreateItem(item.id, 0)
                }
            )
            HStack(alignment: .top, spacing: 4) {
                if let leftAdornment = leftAdornment {
                    leftAdornment(item)
                        .opacity(opacity)
                        .frame(
                            height: RowConstants.horizontalAdornmentHeight,
                            alignment: .center
                        )
                }
                ZStack(alignment: .leading) {
                    titleText
                    editableField
                }
                .padding(.vertical, RowConstants.verticalTextPadding)
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
            if let bottomAdornment {
                bottomAdornment(item)
            }
            NewRowTriggerView(
                showLowerDivider: true,
                onCreateItem: {
                    guard !listManager.isSelectMode else {
                        listManager.toggleItem(item)
                        return
                    }

                    onCreateItem(item.id, 1)
                }
            )
        }
        .opacity(opacity)
    }

    // Static Text
    private var titleText: some View {
        Text(item.title)
            .foregroundColor(Color.label)
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
                    focusController.focusedId = item.id
                }
            }
    }

    // Textfield
    private var editableField: some View {
        RowTextfieldView(
            text: $item.title,
            isFocused: isFocusedBinding,
            height: $height,
            toolbarIcons: toolbarIcons,
            accentColor: tintColor,
            onTapToolbar: { iconName in
                tapToolbar?(iconName, item)
            },
            onEnter: {
                if !item.title.isEmpty {
                    onCreateItem(item.id, 1)
                } else {
                    focusController.focusedId = nil
                }
            },
            onDone: {
                focusController.focusedId = nil
            }
        )
        .tint(tintColor)
        .frame(height: height)
        .foregroundColor(Color.label)
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
                    Task { @MainActor in
                        modelContext.delete(item)
                    }
                } else {
                    item.title = trimmed
                    onTitleChange(item)
                }
            }
        }
    }

}
