//
//  ListItemView.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import SwiftData
import SwiftUI

struct ListItemView<Item: ListItem>: View {
    @Bindable var item: Item
    let isSelected: Bool
    let isSelectDisabled: Bool
    let accentColor: Color
    let textColor: Color

    var onCreateItem:
        (_ baseId: ObjectIdentifier?, _ offset: Int?) ->
            Void
    var onToggleItem: (_ id: ObjectIdentifier) -> Void
    var onValueChange: (_ id: ObjectIdentifier, _ value: String) -> Void

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var focusController: FocusController

    // Will be updated dynamically within the NonBlurringTextfield.
    @State private var height: CGFloat = 0

    @State private var isFocused: Bool = false
    @State private var debounceTask: Task<Void, Never>? = nil

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            // Upper Item Trigger
            NewItemTrigger(onCreateItem: {
                onCreateItem(item.id, nil)
            })

            // Row Content
            HStack(alignment: .top, spacing: 12) {
                // Item Toggle
                HStack(alignment: .center) {
                    ListItemToggleView(
                        isSelected: isSelected,
                        isDisabled: isSelectDisabled,
                        accentColor: accentColor
                    ) {
                        onToggleItem(item.id)
                    }
                }
                .frame(height: 26)

                // Text
                ZStack(alignment: .leading) {
                    Text(item.title)
                        .foregroundColor(textColor)
                        .opacity(isFocused ? 0 : 1)
                        .font(.system(size: 14))
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)

                    ListTextfieldView(
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
                    .foregroundColor(textColor)
                    .opacity(isFocused ? 1 : 0)
                    .tint(accentColor)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 5)

                // Optional Time Value TODO: move out of this file
                //        if let timeValues = timeValues {
                //          HStack(alignment: .center) {
                //            TimeValue(
                //              time: timeValues["time"] ?? "",
                //              indicator: timeValues["indicator"] ?? "",
                //              detail: timeValues["detail"] ?? "",
                //              disabled: isSelected
                //            ) {
                //              onOpenTimeModal(["id": id])
                //            }
                //          }
                //          .frame(height: 26)
                //        }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
            .alignmentGuide(.listRowSeparatorTrailing) {
                $0[.trailing]
            }
            .onTapGesture {
                if !isSelected {
                    isFocused = true
                }
            }
            .onAppear {
                // text = item.title
                if item.title.isEmpty {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isFocused = true
                    }
                }
            }

            // Debounce the external save each time the text changes.
            //      .onChange(of: text) { newValue in
            //          guard newValue != item.title else { return }
            //
            //          // TODO: update this to just trigger external save?
            //
            //        debounceTask?.cancel()
            //
            //        debounceTask = Task {
            //          try? await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second
            //          guard !Task.isCancelled else { return }
            //          onValueChange(["value": newValue, "id": id])
            //        }
            //      }

            // TODO: test working with bindable now (time value update triggers update here?
            // Sync text when value changes externally.
            //      .onChange(of: item.title) { newValue in
            //        if text != newValue {
            //          text = newValue
            //        }
            //      }

            // Blur the textfield when this item has been selected.
            .onChange(of: isSelected) { _, newIsSelected in
                if newIsSelected == true {
                    isFocused = false
                }
            }

            // Handle focus side effects.
            .onChange(of: isFocused) { _, newIsFocused in
                if newIsFocused {
                    // Mark the global focused ID so other fields are blurred.
                    focusController.focusedId = item.id
                } else {
                    let trimmed = item.title.trimmingCharacters(
                        in: .whitespacesAndNewlines
                    )

                    // TODO: trigger external save immediately
                    if trimmed.isEmpty {
                        modelContext.delete(item)
                    } else if trimmed != item.title {
                        //  onValueChange(trimmed, id)
                    }

                    // Immediately trigger the item save.

                    // TODO: trigger external save immediately
                    //          debounceTask?.cancel()
                    //
                    //          let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    //
                    //          if trimmed.isEmpty {
                    //            onDeleteItem(["id": id])
                    //          } else if trimmed != item.title {
                    //            onValueChange(["value": trimmed, "id": id])
                    //          }
                }
            }

            // Blur the textfield when a different field is focused.
            .onChange(of: focusController.focusedId) { _, newFocusedId in
                if newFocusedId != item.id,
                    isFocused == true
                {
                    isFocused = false
                }
            }

            // Lower Item Trigger
            NewItemTrigger(onCreateItem: {
                onCreateItem(item.id, 1)
            })
        }
        .frame(maxWidth: .infinity, alignment: .top)
        .listRowInsets(EdgeInsets())
        .listRowSeparatorTint(Color(uiColor: .quaternaryLabel))
        .listRowBackground(Color.clear)
        .padding(.horizontal, 16)
    }
}
