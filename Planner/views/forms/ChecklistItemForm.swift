//
//  ChecklistItemFormView.swift
//  Planner
//
//  Created by Alex Green on 12/14/25.
//

import SwiftUI
import SwiftData

struct ChecklistItemFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var draft: ChecklistItem

    private let sourceItem: ChecklistItem?
    private let parent: ChecklistItem?

    init(item: ChecklistItem? = nil, parent: ChecklistItem? = nil) {
        self.sourceItem = item
        self.parent = parent

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
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listSectionMargins(.vertical, 0)
                }

                Section {
                    HStack {
                        ForEach(ChecklistColorOption.allCases, id: \.self) { c in
                            Image(
                                systemName: c == draft.color
                                    ? "circle.fill" : "circle"
                            )
                            .foregroundColor(c.swiftUIColor)
                            .imageScale(.large)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .contentShape(Circle())
                            .onTapGesture {
                                draft.color = c
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listSectionMargins(.top, 0)
            }
            .scrollDisabled(true)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Submit", systemImage: "checkmark") {
                        if let sourceItem {
                            // Edit the existing item.
                            sourceItem.title = draft.title
                            sourceItem.color = draft.color
                            sourceItem.type = draft.type
                            try! modelContext.save()
                        } else {
                            // Create the new item.
                            let sorted = parent?.items.sorted { $0.sortIndex < $1.sortIndex }
                            let sortIndex = (sorted?.last?.sortIndex ?? 0) + 8
                            let newItem = ChecklistItem(
                                type: draft.type,
                                title: draft.title,
                                color: draft.color,
                                sortIndex: sortIndex,
                                parent: parent
                            )
                            modelContext.insert(newItem)
                            try! modelContext.save()
                        }
                        dismiss()
                    }
                    .tint(
                        draft.title.isEmpty
                            ? Color(uiColor: .label) : draft.color.swiftUIColor
                    )
                    .disabled(draft.title.isEmpty)
                }
            }
        }
    }
}
