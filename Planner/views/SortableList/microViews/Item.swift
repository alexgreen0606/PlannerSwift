//
//  ItemView.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import SwiftData
import SwiftUI

struct ItemView<Item: ListItem, StartAdornment: View, EndAdornment: View>: View {
    @Bindable var item: Item
    let tint: (_ item: Item) -> Color
    let showChecked: Bool
    let isSelectDisabled: Bool
    let showUpperDivider: Bool
    let startAdornment: ((_ item: Item) -> StartAdornment)?
    let endAdornment: ((_ item: Item) -> EndAdornment)?
    let customToggleConfig: CustomIconConfig<Item>?
    let onCreateItem:
        (_ baseId: PersistentIdentifier?, _ offset: Int) ->
            Void
    let onTitleChange: (_ item: Item) -> Void
    let isItemChecked: ((_ item: Item) -> Bool)?

    @Environment(\.scenePhase) private var appPhase
    @Environment(\.modelContext) private var modelContext

    @EnvironmentObject var focusController: FocusController
    @EnvironmentObject var listManager: ListManager<Item>

    // Will be updated dynamically within the TextfieldView.
    @State private var height: CGFloat = 0

    @State private var isFocused: Bool = false
    @State private var debounceTask: Task<Void, Never>? = nil
    
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
        rowContent
            .frame(maxWidth: .infinity, alignment: .top)
            .listRowInsets(EdgeInsets())
            .discreetListItem()
            .padding(.horizontal, 16)

            // Trigger focus on render for empty items (new items).
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

            // Blur the textfield when select mode begins.
            .onChange(of: listManager.isSelectMode) { _, isSelectMode in
                if isSelectMode {
                    isFocused = false
                    dismissKeyboard()
                }
            }

            // Blur the textfield when the app exits focus.
            .onChange(of: appPhase) { _, phase in
                if phase == .inactive {
                    isFocused = false
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
            item: item,
            tint: tintColor,
            isChecked: isChecked,
            isDisabled: isSelectDisabled,
            opacity: opacity,
            customIconConfig: customToggleConfig
        ) {
            listManager.toggleItem(item)
        }
        .frame(height: 44, alignment: .center)
    }

    // Item Text
    private var textStack: some View {
        VStack(spacing: 0) {
            NewItemTriggerView(
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
                if let startAdornment = startAdornment {
                    startAdornment(item)
                        .opacity(opacity)
                        .frame(height: 28, alignment: .center)
                }
                ZStack(alignment: .leading) {
                    titleText
                    editableField
                }
                .padding(.vertical, 3)
                if let endAdornment = endAdornment {
                    endAdornment(item)
                        .opacity(opacity)
                        .frame(height: 28, alignment: .center)
                }
            }
            .frame(minHeight: 28)
            NewItemTriggerView(
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
            .foregroundColor(Color(uiColor: .label))
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
                    isFocused = true
                }
            }
    }

    // Textfield
    private var editableField: some View {
        TextfieldView(
            text: $item.title,
            isFocused: $isFocused,
            height: $height,
            accentColor: tintColor,
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
    
    func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

}
