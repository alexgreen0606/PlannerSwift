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
    private let onCreated: (ChecklistItem) -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var draft: ChecklistItem

    var isDirty: Bool {
        draft.title != sourceItem?.title || draft.color != sourceItem?.color
            || draft.type != sourceItem?.type
    }

    init(
        item: ChecklistItem? = nil,
        parent: ChecklistItem? = nil,
        onCreated: @escaping (ChecklistItem) -> Void
    ) {
        self.sourceItem = item
        self.parent = parent
        self.onCreated = onCreated

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

                if sourceItem == nil || sourceItem!.items.isEmpty {
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
    }

    private func handleSave() {
        if let sourceItem {
            // Edit the existing item.
            sourceItem.title = draft.title
            sourceItem.color = draft.color
            sourceItem.type = draft.type
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

            onCreated(newItem)
        }

        do {
            try modelContext.save()
        } catch {
            assertionFailure(
                "Error saving checklist item: \(error)"
            )
        }

        dismiss()
    }
}
