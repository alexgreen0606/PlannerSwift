//
//  ChecklistItemForm.swift
//  Planner
//
//  Created by Alex Green on 12/14/25.
//

import SwiftData
import SwiftUI
import SwiftUIIntrospect

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
    @State private var hasTitleAutoFocused = false

    @FocusState private var isTitleFocused: Bool
    @State private var hasAutoFocused = false

    private var isEditForm: Bool { sourceItem != nil }

    private var canSave: Bool {
        !draftChecklistItem.title.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                FormTitleFieldView(
                    text: $draftChecklistItem.title,
                    hasAutoFocused: $hasTitleAutoFocused,
                    isFocused: $isTitleFocused
                )
                .textInputAutocapitalization(.words)

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
        .presentationDetents([.height(isEditForm ? 220 : 275)])
        .presentationBackground(.clear)
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
