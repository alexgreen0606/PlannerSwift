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
    @State private var selectedItem: ChecklistItem? = nil
    @State private var currentItemId: PersistentIdentifier
    @State private var folderPath = NavigationPath()
    @State private var root: ChecklistItem

    private var selectionLabel: String {
        guard let selectedItem else {
            return "Select a \(mode.rawValue)"
        }

        return selectedItem.title
    }

    init(currentItem: ChecklistItem) {
        var path = NavigationPath()
        var items: [ChecklistItem] = []

        var startNode: ChecklistItem? =
            currentItem.type == .folder
            ? currentItem
            : currentItem.parent

        var foundRoot: ChecklistItem?

        while let current = startNode {
            startNode = current.parent

            if current.parent != nil {
                // Only append folders that have checklists.
                if currentItem.type == .checklist && current.type == .folder {
                    if current.hasChecklists(excluding: currentItem.id) {
                        items.append(current)
                    }
                } else {
                    items.append(current)
                }
            } else {
                foundRoot = current
            }
        }

        guard let root = foundRoot else {
            fatalError("ChecklistItem hierarchy is broken: root not found")
        }

        self.root = root

        for item in items.reversed() {
            path.append(item)
        }

        self.folderPath = path
        self.mode = currentItem.type == .folder ? .folder : .checklist
        self.currentItemId = currentItem.id
    }

    var body: some View {
        NavigationStack(path: $folderPath) {
            folderView(root)
                .navigationDestination(for: ChecklistItem.self) { folder in
                    folderView(folder)
                }
        }
        .presentationDetents([.height(380), .height(2600)])
    }

    @ViewBuilder
    private func folderView(_ folder: ChecklistItem) -> some View {
        folderDestination(folder)
            .navigationTitle("Transfer Items")
            .navigationSubtitle(selectionLabel)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                topRightToolbar
                topLeftToolbar(folder)
            }
    }

    @ViewBuilder
    private func folderDestination(_ folder: ChecklistItem) -> some View {
        List {
            Section {
                ForEach(
                    folder.items
                        .filter { item in
                            guard
                                item.id != currentItemId
                                    && !listManager.selectedItemIds.contains(
                                        item.id
                                    )
                            else { return false }

                            // If in folder mode, only show folders.
                            if mode == .folder {
                                return item.type == .folder
                            }

                            // If in checklist mode and item is a folder, only show if it has checklists.
                            if mode == .checklist, item.type == .folder {
                                return item.hasChecklists(
                                    excluding: currentItemId
                                )
                            }

                            return true
                        }
                        .sorted { $0.sortIndex < $1.sortIndex },
                    id: \.self
                ) { item in
                    itemRow(item)
                }
            } header: {
                Text(folder.fullPath)
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color(.systemBackground))
    }

    private func topLeftToolbar(_ folder: ChecklistItem) -> some ToolbarContent {
        Group {
            if folder.parent != nil {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Back", systemImage: "chevron.left") {
                        folderPath.removeLast()
                        
                        if mode == .folder {
                            // Select the folder we are navigating back to.
                            selectedItem = folder.parent
                        }
                    }
                }
            }
        }
    }

    private var topRightToolbar: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            Button("Submit", systemImage: "checkmark", role: .confirm) {
                guard let destination = selectedItem else {
                    return
                }

                do {
                    try modelContext.transaction {
                        destination.inheritItems(listManager.selectedItems)
                    }
                } catch {
                    assertionFailure("Failed to transfer items: \(error)")
                    return
                }

                listManager.toggleSelectMode()

                dismiss()
            }
            .disabled(selectedItem == nil)
            .tint(selectedItem?.color.swiftUIColor ?? .blue)
        }
    }

    private func itemRow(_ item: ChecklistItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading) {
                Image(
                    systemName: selectedItem == item
                        ? "checkmark" : item.type.iconName
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
        }
        .id(item.id)
        .frame(maxWidth: .infinity, alignment: .leading)
        .opacity(rowOpacity(for: item))
        .contentShape(Rectangle())
        .onTapGesture {
            if item.type == .checklist || mode == .folder {
                selectedItem = selectedItem == item ? nil : item

                if item.type == .checklist { return }
            }

            folderPath.append(item)
        }
    }

    private func rowOpacity(for item: ChecklistItem) -> Double {
        guard let selected = selectedItem else {
            return 1
        }

        if item == selected || item.isAncestor(of: selected) {
            return 1
        }

        return 0.3
    }

}
