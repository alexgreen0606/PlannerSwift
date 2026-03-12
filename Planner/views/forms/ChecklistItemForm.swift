//
//  ChecklistItemForm.swift
//  Planner
//
//  Created by Alex Green on 12/14/25.
//

import SwiftData
import SwiftUI

// Clean

struct ChecklistItemFormView: View {
    private let sourceItem: ChecklistItem?
    private let parent: ChecklistItem?
    private let onSave: ((UUID?) -> Void)?

    init(
        item: ChecklistItem? = nil,
        parent: ChecklistItem?,
        onSave: ((UUID?) -> Void)? = nil
    ) {
        self.sourceItem = item
        self.parent = parent
        self.onSave = onSave

        if let item {
            _draftChecklistItem = State(
                initialValue: ChecklistItem(
                    type: item.type,
                    title: item.title,
                    color: item.color,
                    sortIndex: 0
                )
            )
        } else {
            _draftChecklistItem = State(
                initialValue: ChecklistItem(
                    sortIndex: 0
                )
            )
        }
    }

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var draftChecklistItem: ChecklistItem

    @FocusState private var isFocused: Bool

    private var canSave: Bool {
        !draftChecklistItem.title.isEmpty
            && (draftChecklistItem.title != sourceItem?.title
                || draftChecklistItem.color != sourceItem?.color
                || draftChecklistItem.type != sourceItem?.type)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $draftChecklistItem.title)
                        .textInputAutocapitalization(.words)

                        // Increase the focusable area of the field.
                        .focused($isFocused)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            isFocused = true
                        }
                }
                .listSectionMargins(.top, 0)

                if sourceItem == nil {
                    Section {
                        Picker("Type", selection: $draftChecklistItem.type) {
                            Text("Checklist").tag(ChecklistItemType.checklist)
                            Text("Folder").tag(ChecklistItemType.folder)
                        }
                        .pickerStyle(.segmented)

                    }
                    .discreetListItem()
                    .listSectionMargins(.vertical, 0)
                }

                Section {
                    HStack {
                        ForEach(ChecklistItemColor.allCases, id: \.self) {
                            itemColor in
                            Image(
                                systemName: itemColor
                                    == draftChecklistItem.color
                                    ? "circle.fill" : "circle"
                            )
                            .foregroundColor(itemColor.swiftUIColor)
                            .imageScale(.large)
                            .onTapGesture {
                                draftChecklistItem.color = itemColor
                            }

                            if itemColor != ChecklistItemColor.allCases.last {
                                Spacer()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .discreetListItem()
                .listSectionMargins(.top, 0)
            }
            .scrollDisabled(true)
            .navigationTitle(
                sourceItem == nil
                    ? "Create Item"
                    : "Edit \(draftChecklistItem.type.rawValue.capitalizedFirst)"
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                submitButton
            }
        }
        .presentationDetents([.height(250)])
    }

    // MARK: - Toolbars

    private var submitButton: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button("Submit", systemImage: "checkmark", action: handleSave)
                .tint(
                    draftChecklistItem.title.isEmpty
                        ? Color.label : draftChecklistItem.color.swiftUIColor
                )
                .disabled(!canSave)
        }
    }

    // MARK: - Functions

    private func handleSave() {
        let newItemId = modelContext.handleChecklistItemChange(
            sourceItem: sourceItem,
            parent: parent,
            draftChecklistItem: draftChecklistItem
        )

        dismiss()
        onSave?(newItemId)
    }

}
