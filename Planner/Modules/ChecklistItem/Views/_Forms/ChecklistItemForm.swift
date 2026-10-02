//
//  ChecklistItemForm.swift
//  Planner
//
//  Created by Alex Green on 12/14/25.
//

import SwiftData
import SwiftUI

struct ChecklistItemFormView: View {
    private let sourceItem: ChecklistItem?
    private let parentItem: ChecklistItem?
    private let sortedSiblingItems: [ChecklistItem]?
    private let onDelete: (() -> Void)?

    // MARK: Create Checklist Item
    init(
        parentItem: ChecklistItem,
        sortedSiblingItems: [ChecklistItem]
    ) {
        self.sourceItem = nil
        self.parentItem = parentItem
        self.sortedSiblingItems = sortedSiblingItems
        self.onDelete = nil

        _draftChecklistItem = State(
            initialValue: ChecklistItem()
        )
    }

    // MARK: Edit Checklist Item
    init(
        sourceItem: ChecklistItem,
        onDelete: (() -> Void)? = nil
    ) {
        self.sourceItem = sourceItem
        self.parentItem = sourceItem.parent
        self.sortedSiblingItems = nil
        self.onDelete = onDelete

        _draftChecklistItem = State(
            initialValue: ChecklistItem(
                draftOf: sourceItem
            )
        )
    }

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var draftChecklistItem: ChecklistItem

    @State private var hasTitleAutoFocused = false
    @State private var showDeleteConfirmation = false

    @FocusState private var isTitleFocused: Bool
    @FocusState private var isValueFocused: Bool

    private var canSave: Bool {
        !draftChecklistItem.title.trimmed.isEmpty
    }

    private var isCreateForm: Bool {
        sourceItem == nil
    }

    private var color: Color {
        switch draftChecklistItem.type {
        case .item:
            return parentItem?.color.swiftUIColor ?? Color.red
        case .checklist, .folder:
            return draftChecklistItem.color.swiftUIColor
        }
    }

    private var showColorSection: Bool {
        draftChecklistItem.type != .item
    }

    private var showDeleteButton: Bool {
        sourceItem != nil && sourceItem!.parent != nil
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                FormTitleFieldView(
                    text: $draftChecklistItem.title,
                    hasAutoFocused: $hasTitleAutoFocused,
                    isFocused: $isTitleFocused
                )
                .textInputAutocapitalization(.words)

                typeSection
                colorSection
                advancedSection
            }
            .scrollDisabled(true)
            .toolbar {
                FormSaveButtonView(
                    canSave: canSave,
                    tint: draftChecklistItem.title.isEmpty
                        ? Color.label : color,
                    save: saveChecklistItem
                )

                deleteButton
            }
            .navigationTitle(
                isCreateForm
                    ? "Create Item"
                    : "Edit \(draftChecklistItem.type.rawValue.capitalized)"
            )
            .navigationBarTitleDisplayMode(.inline)
        }
        .safeAreaBar(edge: .bottom) {
            valueKeyboardAdornment
        }
        .presentationBackground(.clear)
        .presentationDetents([.height(390)])
    }

    // MARK: - Toolbars

    @ToolbarContentBuilder
    private var deleteButton: some ToolbarContent {
        if showDeleteButton, let sourceItem {
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
                        delete: deleteChecklistItem
                    ),
                    isPresented: $showDeleteConfirmation
                )
            }
            .sharedBackgroundVisibility(.hidden)
        }
    }

    // MARK: - View Builders

    @ViewBuilder
    private var typeSection: some View {
        if isCreateForm {
            Section {
                Picker("", selection: $draftChecklistItem.type) {
                    Text("Checklist").tag(ChecklistItemType.checklist)
                    Text("Folder").tag(ChecklistItemType.folder)
                }
                .pickerStyle(.segmented)
            }
            .listSectionMargins(.vertical, 0)
            .discreetListItem()
        }
    }

    @ViewBuilder
    private var colorSection: some View {
        if showColorSection {
            Section {
                HStack {
                    ForEach(
                        ChecklistItemColor.allCases.enumerated(),
                        id: \.element
                    ) {
                        index,
                        itemColor in
                        if index != 0 {
                            Spacer()
                        }

                        Image(
                            systemName: itemColor
                                == draftChecklistItem.color
                                ? "circle.fill" : "circle"
                        )
                        .imageScale(.large)
                        .foregroundColor(itemColor.swiftUIColor)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            draftChecklistItem.color = itemColor
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .listSectionMargins(.vertical, 0)
            .discreetListItem()
        }
    }

    private var advancedSection: some View {
        Section("Advanced") {
            switch draftChecklistItem.type {
            case .item:
                HStack {
                    Text("Value")

                    CurrencyTextFieldView(
                        value: $draftChecklistItem.valueInt,
                        textColor: isValueFocused
                            || draftChecklistItem.draftValue.isZero
                            ? Color.label
                            : draftChecklistItem.draftValue < 0
                                ? Color.red : Color.green
                    )
                    .focused($isValueFocused)
                    .tint(color)
                }
            case .folder, .checklist:
                Toggle(
                    "Show Values",
                    isOn: $draftChecklistItem.showItemValues
                )
                .tint(color)
            }
        }
    }

    @ViewBuilder
    private var valueKeyboardAdornment: some View {
        if isValueFocused {
            HStack(alignment: .bottom) {
                Picker(
                    "",
                    selection: $draftChecklistItem.valueSign
                ) {
                    Text("−").tag(-1)
                    Text("+").tag(1)
                }
                .pickerStyle(.segmented)
                .frame(width: 100)

                Spacer()

                GlassIconButtonView(
                    systemImageName: "checkmark",
                    onTap: {
                        isValueFocused = false
                    }
                )
            }
            .padding(8)
        }
    }

    // MARK: - Functions

    private func saveChecklistItem() {
        modelContext.saveChecklistItem(
            sourceItem: sourceItem,
            parentItem: parentItem,
            sortedSiblingItems: sortedSiblingItems,
            draftItem: draftChecklistItem
        )

        dismiss()
    }

    private func deleteChecklistItem() {
        guard let sourceItem else { return }

        dismiss()

        modelContext.safeDelete(sourceItem)
        onDelete?()
    }
}
