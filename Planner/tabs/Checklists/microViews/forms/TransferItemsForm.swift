//
//  TransferItemsForm.swift
//  Planner
//
//  Created by Alex Green on 1/26/26.
//

import SwiftData
import SwiftUI

struct TransferItemsFormView: View {

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject var listManager: ListManager<ChecklistItem>

    @State private var mode: ChecklistItemType
    @State private var selectedItem: ChecklistItem
    @State private var currentItemId: PersistentIdentifier
    @State private var currentFolder: ChecklistItem

    private var selectionLabel: String {
        "Select a \(mode.rawValue)"
    }

    init(currentItem: ChecklistItem) {
        self.currentFolder =
            currentItem.type == .folder
            ? currentItem
            : currentItem.parent!
        self.mode = currentItem.type == .folder ? .folder : .checklist
        self.currentItemId = currentItem.id
        self.selectedItem = currentItem
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(
                        currentFolder.items
                            .filter { item in
                                guard
                                    item.id != currentItemId
                                        && !listManager.selectedItemIds
                                            .contains(
                                                item.id
                                            )
                                else { return false }

                                // If in folder mode, only show folders.
                                if mode == .folder {
                                    return item.type == .folder
                                }

                                // If in checklist mode and item is a folder, only show if it has checklists.
                                if mode == .checklist, item.type == .folder {
                                    return item.hasChecklists()
                                }

                                return true
                            }
                            .sorted { $0.sortIndex < $1.sortIndex },
                        id: \.self
                    ) { item in
                        itemRow(item)
                    }
                } header: {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 8) {
                            Image(systemName: selectedItem.type.iconName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                                .foregroundStyle(
                                    selectedItem.color.swiftUIColor
                                )

                            VStack(alignment: .leading) {
                                Text(selectedItem.title)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color(uiColor: .label))

                                Text("Destination")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(
                                        Color(uiColor: .secondaryLabel)
                                    )
                            }
                        }
                        .glassChip(color: nil, onTap: nil, height: 40)

                        VStack(alignment: .leading, spacing: 6) {
                            AccentButtonView(
                                label: currentFolder.parent?.title ?? "",
                                systemImage: "chevron.left"
                            ) {
                                guard let parent = currentFolder.parent else {
                                    return
                                }

                                currentFolder = parent

                                if mode == .folder {
                                    // Select the folder we are navigating back to.
                                    selectedItem = parent
                                }
                            }
                            .opacity(currentFolder.parent == nil ? 0 : 1)

                            Text(currentFolder.title)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .background(Color(.systemBackground))
            .navigationTitle("Transfer Items")
            .navigationSubtitle(selectionLabel)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                topRightToolbar
                topLeftToolbar(currentFolder)
            }
        }
    }

    @ToolbarContentBuilder
    private func topLeftToolbar(_ folder: ChecklistItem) -> some ToolbarContent
    {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel", systemImage: "xmark") {
                dismiss()
            }
        }
    }

    @ToolbarContentBuilder
    private var topRightToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("Submit", systemImage: "checkmark", role: .confirm) {
                guard selectedItem.id != currentItemId else {
                    return
                }

                do {
                    try modelContext.transaction {
                        selectedItem.inheritItems(listManager.selectedItems)
                    }
                } catch {
                    assertionFailure("Failed to transfer items: \(error)")
                    return
                }

                listManager.toggleSelectMode()

                dismiss()
            }
            .disabled(selectedItem.id == currentItemId)
            .tint(selectedItem.color.swiftUIColor)
        }
    }

    private func itemRow(_ item: ChecklistItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading) {
                Image(
                    systemName: item.type.iconName
                )
                .foregroundColor(item.color.swiftUIColor)
                .imageScale(.medium)
                .frame(
                    width: 26,
                    height: 53,
                    alignment: .center
                )
            }
            .frame(height: 19)

            Text(item.title)
                .font(.system(size: UIConstants.listItemFontSize))
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            if item.type == .folder {
                HStack(alignment: .center) {
                    Image(systemName: "chevron.right")
                        .foregroundColor(
                            Color(uiColor: .tertiaryLabel)
                        )
                }
                .frame(height: 19)
            }

            if selectedItem == item {
                Image(systemName: "checkmark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture {
            if item.type == .checklist || mode == .folder {
                selectedItem = item

                if item.type == .checklist { return }
            }

            currentFolder = item
        }
    }

}
