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
    private let onDelete: (() -> Void)?

    init(
        item: ChecklistItem? = nil,
        parent: ChecklistItem?,
        onSave: ((UUID?) -> Void)? = nil,
        onDelete: (() -> Void)? = nil
    ) {
        self.sourceItem = item
        self.parent = parent
        self.onSave = onSave
        self.onDelete = onDelete

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
    @State private var hasAutoFocused = false
    @State private var showDeleteConfirmation = false

    @FocusState private var isTitleFocused: Bool

    private var canSave: Bool {
        !draftChecklistItem.title.trimmingCharacters(
            in: .whitespacesAndNewlines
        ).isEmpty
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
                    : "Edit \(draftChecklistItem.type.rawValue.capitalized)"
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                submitButton
                deleteButton
            }
        }
        .presentationDetents([.height(260)])
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

    @ToolbarContentBuilder
    private var deleteButton: some ToolbarContent {
        if let sourceItem {
            ToolbarItem(placement: .bottomBar) {
                ActionButtonView(
                    label: "Delete \(sourceItem.type.rawValue.capitalized)",
                    systemImage: "trash",
                    color: Color.red,
                    onTap: {
                        showDeleteConfirmation = true
                    }
                )
                .withConfirmation(
                    deleteChecklistItemConfig(
                        item: sourceItem,
                        inForm: true,
                        delete: {
                            modelContext.safeDelete(sourceItem)
                            dismiss()
                            onDelete?()
                        }
                    ),
                    isPresented: $showDeleteConfirmation
                )
            }
            .sharedBackgroundVisibility(.hidden)
        }
    }

    // MARK: - Functions

    private func handleSave() {
        let newItemId = modelContext.updateChecklistItem(
            sourceItem: sourceItem,
            parent: parent,
            draftChecklistItem: draftChecklistItem
        )

        dismiss()
        onSave?(newItemId)
    }

}
