//
//  ChecklistItemFormView.swift
//  Planner
//
//  Created by Alex Green on 12/14/25.
//

import SwiftData
import SwiftUI

struct ChecklistItemFormView: View {
    private let sourceItem: ChecklistItem?
    private let parent: ChecklistItem?
    private let onSave: (ChecklistItem) -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var draft: ChecklistItem

    private var isDirty: Bool {
        draft.title != sourceItem?.title || draft.color != sourceItem?.color
            || draft.type != sourceItem?.type
    }
    
    private var showTypePicker: Bool {
        guard let sourceItem else {
            return true
        }
        
        return sourceItem.items.isEmpty && parent != nil
    }

    init(
        item: ChecklistItem? = nil,
        parent: ChecklistItem?,
        onSave: @escaping (ChecklistItem) -> Void
    ) {
        self.sourceItem = item
        self.parent = parent
        self.onSave = onSave

        if let item {
            _draft = State(
                initialValue: ChecklistItem(
                    type: item.type,
                    title: item.title,
                    color: item.color,
                    sortIndex: 0
                )
            )
        } else {
            _draft = State(
                initialValue: ChecklistItem(
                    sortIndex: 0
                )
            )
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Title", text: $draft.title)
                        .textInputAutocapitalization(.words)
                }
                .listSectionMargins(.top, 0)

                if showTypePicker {
                    Section {
                        Picker("Type", selection: $draft.type) {
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
                            c in
                            Image(
                                systemName: c == draft.color
                                    ? "circle.fill" : "circle"
                            )
                            .foregroundColor(c.swiftUIColor)
                            .imageScale(.large)
                            .onTapGesture {
                                draft.color = c
                            }

                            if c != ChecklistItemColor.allCases.last {
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
                    : "Edit \(draft.type.rawValue.capitalizedFirst)"
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit", systemImage: "checkmark") {
                        handleSave()
                    }
                    .tint(
                        draft.title.isEmpty
                            ? Color(uiColor: .label) : draft.color.swiftUIColor
                    )
                    .disabled(draft.title.isEmpty || !isDirty)
                }
            }
        }
        .presentationDetents([.height(250)])
    }

    private func handleSave() {
        let savedItem: ChecklistItem
        
        if let sourceItem {
            // Edit the existing item.
            sourceItem.title = draft.title
            sourceItem.color = draft.color
            sourceItem.type = draft.type
            
            savedItem = sourceItem
        } else {
            // Create the new item.
            let sorted = parent?.items.sorted {
                $0.sortIndex < $1.sortIndex
            }
            let sortIndex = (sorted?.last?.sortIndex ?? 0) + 8
            let newItem = ChecklistItem(
                type: draft.type,
                title: draft.title,
                color: draft.color,
                sortIndex: sortIndex,
                parent: parent
            )
            modelContext.insert(newItem)

            savedItem = newItem
        }

        do {
            try modelContext.save()
        } catch {
            assertionFailure(
                "Error saving checklist item: \(error)"
            )
        }
        
        onSave(savedItem)
        dismiss()
    }
}
