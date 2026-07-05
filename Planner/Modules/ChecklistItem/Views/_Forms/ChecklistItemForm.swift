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
        onDelete: @escaping () -> Void
    ) {
        self.sourceItem = sourceItem
        self.parentItem = sourceItem.parent
        self.sortedSiblingItems = nil
        self.onDelete = onDelete

        _draftChecklistItem = State(
            initialValue: ChecklistItem(
                title: sourceItem.title,
                type: sourceItem.type,
                color: sourceItem.color
            )
        )
    }

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var draftChecklistItem: ChecklistItem

    @State private var hasTitleAutoFocused = false
    @State private var showDeleteConfirmation = false

    @FocusState private var isTitleFocused: Bool

    private var canSave: Bool {
        !draftChecklistItem.title.trimmed.isEmpty
    }

    private var isCreateForm: Bool {
        sourceItem == nil
    }

    private var isRootFolder: Bool {
        sourceItem != nil && sourceItem!.parent == nil
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
            }
            .scrollDisabled(true)
            .toolbar {
                FormSaveButtonView(
                    canSave: canSave,
                    tint: draftChecklistItem.title.isEmpty
                        ? Color.label : draftChecklistItem.color.swiftUIColor,
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
        .presentationBackground(.clear)
        .presentationDetents([.height(isRootFolder ? 210 : 260)])
    }

    // MARK: - Toolbars

    @ToolbarContentBuilder
    private var deleteButton: some ToolbarContent {
        if let sourceItem, !isRootFolder {
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

    private var colorSection: some View {
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
        .listSectionMargins(.top, 0)
        .discreetListItem()
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
