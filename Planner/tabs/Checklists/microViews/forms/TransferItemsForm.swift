//
//  TransferItemsForm.swift
//  Planner
//
//  Created by Alex Green on 1/26/26.
//

import SwiftData
import SwiftUI

struct TransferItemsFormView: View {
    let sourceItem: ChecklistItem
    
    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @EnvironmentObject var listManager: ListManager<ChecklistItem>

    @State private var mode: ChecklistItemType
    @State private var selectedItem: ChecklistItem?
    @State private var currentFolder: ChecklistItem

    private var selectionLabel: String {
        let count = listManager.selectedItems.count
        return
            "\(count == 0 ? "No" : String(count)) item\(count == 1 ? "" : "s")"
    }

    var options: [ChecklistItem] {
        currentFolder.items
            .filter { item in
                guard
                    item.id != sourceItem.id
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
            .sorted { $0.sortIndex < $1.sortIndex }
    }

    init(currentItem: ChecklistItem) {
        self.currentFolder =
            currentItem.type == .folder
            ? currentItem
            : currentItem.parent!
        self.mode = currentItem.type == .folder ? .folder : .checklist
        self.sourceItem = currentItem
    }

    var body: some View {
        NavigationStack {
            ZStack {
                List {
                    Section {
                        ForEach(
                            options,
                            id: \.self
                        ) { item in
                            itemRow(item)
                        }
                    } header: {
                        VStack(alignment: .leading, spacing: 6) {
                            if let parent = currentFolder.parent {
                                AccentButtonView(
                                    label: parent.title,
                                    systemImage: "chevron.left"
                                ) {
                                    currentFolder = parent

                                    if mode == .folder {
                                        // Select the folder we are navigating back to.
                                        selectedItem = parent
                                    }
                                }
                            }

                            Text(currentFolder.title)
                        }
                    }
                    .listSectionMargins(.top, 0)
                }
                .overlay {
                    if options.isEmpty {
                        EmptyLabel("No Available \(mode.rawValue.capitalizedFirst)s")
                    }
                }
                .transition(.move(edge: .trailing))
                .id(currentFolder.id)
            }
            .navigationTitle("Transfer \(mode.childrenLabel.capitalizedFirst)")
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemBackground))
            .animation(.easeInOut, value: currentFolder.id)
            .animation(.spring, value: selectedItem != nil)
            .toolbar {
                topRightToolbar
                topLeftToolbar(currentFolder)
            }
            .safeAreaInset(edge: .top) {
                if let selectedItem {
                    HStack {
                        HStack(spacing: 8) {
                            Image(systemName: sourceItem.type.iconName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 14, height: 14)
                                .foregroundStyle(sourceItem.color.swiftUIColor)

                            VStack(alignment: .leading) {
                                Text(selectionLabel)
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundStyle(Color(uiColor: .label))

                                Text(sourceItem.title)
                                    .font(.system(size: 8, weight: .medium))
                                    .foregroundStyle(
                                        Color(uiColor: .secondaryLabel)
                                    )
                            }
                        }
                        .glassChip(color: nil, onTap: nil, height: 30)

                        Image(systemName: "arrow.right")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 12, height: 12)
                            .foregroundStyle(Color(uiColor: .secondaryLabel))

                        HStack(spacing: 8) {
                            Image(systemName: selectedItem.type.iconName)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 18, height: 18)
                                .foregroundStyle(
                                    selectedItem.color.swiftUIColor
                                )

                                Text(selectedItem.title)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundStyle(Color(uiColor: .label))
                        }
                        .glassChip(color: nil, onTap: nil, height: 40)
                        .animation(
                            .spring(
                                response: 0.6,
                                dampingFraction: 0.4
                            ),
                            value: selectedItem.id
                        )
                    }
                    .padding(.horizontal)
                }
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
                guard let selectedItem, selectedItem.id != sourceItem.id else {
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
            .disabled(selectedItem == nil || selectedItem!.id == sourceItem.id)
            .tint(accentColor.swiftUIColor)
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
