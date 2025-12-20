//
//  ItemView.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import SwiftData
import SwiftUI

struct ItemView<Item: ListItem, EndAdornment: View>: View {
    @Bindable var item: Item
    let toggleType: ListToggleType
    let isSelectDisabled: Bool
    let showUpperDivider: Bool
    let endAdornment: ((_ item: Item) -> EndAdornment)?
    let customToggleConfig: CustomIconConfig?
    let onCreateItem:
        (_ baseId: ObjectIdentifier?, _ offset: Int) ->
            Void
    let onTitleChange: (_ item: Item) -> Void

    @AppStorage("showChecked") var showChecked: Bool = false

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var focusController: FocusController
    @EnvironmentObject var listManager: ListManager

    // Will be updated dynamically within the NonBlurringTextfield.
    @State private var height: CGFloat = 0

    @State private var isFocused: Bool = false
    @State private var opacity: Double = 1
    @State private var debounceTask: Task<Void, Never>? = nil

    var isChecked: Bool {
        if toggleType == .staging {
            return listManager.selectedItemIds.contains(item.id)
        }

        if listManager.itemIdsToUncheck.contains(item.id) { return false }
        if listManager.itemIdsToCheck.contains(item.id) { return true }

        return item.isChecked
    }

    var body: some View {
        rowContent
            .frame(maxWidth: .infinity, alignment: .top)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .padding(.horizontal, 16)
            // Trigger focus on render for new items.
            .onAppear {
                if item.title.isEmpty {
                    isFocused = true
                }
            }
            // Blur the textfield when a different field is focused.
            .onChange(of: focusController.focusedId) { _, newFocusedId in
                if newFocusedId != item.id,
                    isFocused
                {
                    isFocused = false
                }
            }
            // Blur the textfield when this item has been selected.
            .onChange(of: isChecked) { _, newIsSelected in
                if newIsSelected == true {
                    isFocused = false
                }
            }
            // Animate the fading away of toggled completion/deletion items.
            .onChange(of: listManager.fadeOutTrigger) {
                if showChecked || toggleType == .staging { return }

                withAnimation(.linear(duration: 0.5)) {
                    opacity = 1
                }

                if listManager.itemIdsToCheck.contains(item.id)
                    || listManager.itemIdsToUncheck.contains(item.id)
                {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        withAnimation(.linear(duration: 2.5)) {
                            opacity = 0
                        }
                    }
                }
            }
            // Revert the fade animation when checked items are marked as visible.
            .onChange(of: showChecked) { _, newShowChecked in
                if newShowChecked {
                    withAnimation(.linear(duration: 0.5)) {
                        opacity = 1
                    }
                }
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
        ItemToggleView(
            type: toggleType,
            isChecked: isChecked,
            isDisabled: isSelectDisabled,
            opacity: opacity,
            customIconConfig: customToggleConfig
        ) {
            listManager.toggleItem(item, type: toggleType)
        }
        .frame(height: 44, alignment: .center)
    }

    // Item Text
    private var textStack: some View {
        VStack(spacing: 0) {
            NewItemTriggerView(
                showUpperDivider: showUpperDivider,
                onCreateItem: {
                    onCreateItem(item.id, 0)
                }
            )
            HStack(alignment: .top, spacing: 4) {
                ZStack(alignment: .leading) {
                    titleText
                    editableField
                }
                .padding(.vertical, 3)
                if let adornment = endAdornment {
                    adornment(item)
                        .opacity(opacity)
                        .frame(height: 28, alignment: .center)
                        .background(Color.yellow)
                }
            }
            .frame(minHeight: 28)
            NewItemTriggerView(
                showLowerDivider: true,
                onCreateItem: {
                    onCreateItem(item.id, 1)
                }
            )
        }
        .opacity(opacity)
    }

    // Static Text
    private var titleText: some View {
        Text(item.title)
            .foregroundColor(Color(uiColor: .label))
            .opacity(isFocused ? 0 : 1)
            .font(.system(size: 17))
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .onTapGesture {
                if !isChecked {
                    isFocused = true
                }
            }
    }

    // Textfield
    private var editableField: some View {
        TextfieldView(
            text: $item.title,
            isFocused: $isFocused,
            height: $height
        ) {
            if !item.title.isEmpty {
                onCreateItem(item.id, 1)
            } else {
                focusController.focusedId = nil
            }
        }
        .frame(height: height)
        .foregroundColor(Color(uiColor: .label))
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
        .onChange(of: isFocused) { oldIsFocused, newIsFocused in
            if newIsFocused {
                // Mark the global focused ID so other fields are blurred.
                focusController.focusedId = item.id
            } else if oldIsFocused {
                debounceTask?.cancel()

                let trimmed = item.title.trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

                if trimmed.isEmpty {
                    modelContext.delete(item)
                } else {
                    item.title = trimmed
                    onTitleChange(item)
                }
            }
        }
    }
}
