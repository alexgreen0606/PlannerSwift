//
//  TransferChecklistItemsForm.swift
//  Planner
//
//  Created by Alex Green on 1/26/26.
//

import SwiftData
import SwiftUI

struct TransferChecklistItemsFormView: View {
    private let sourceItem: ChecklistItem
    private let rootFolder: ChecklistItem
    private let openItem: (ChecklistItem, ChecklistItem) -> Void

    init(
        sourceItem: ChecklistItem,
        selectedIds: Set<UUID>,
        rootFolder: ChecklistItem,
        openItem: @escaping (ChecklistItem, ChecklistItem) -> Void
    ) {
        self.sourceItem = sourceItem
        self.rootFolder = rootFolder
        self.openItem = openItem

        var destinationItem: ChecklistItem?
        var folderPath = NavigationPath()

        let selectableItems = rootFolder.items(
            matching: sourceItem.type,
            excluding: selectedIds,
            skipId: sourceItem.stableId
        )

        for i in selectableItems {
            print("debug | Available: \(i.title)")
        }

        if selectableItems.count == 1, let firstItem = selectableItems.first {
            // MARK: Only one option exists. Default select and navigate to it.

            destinationItem = firstItem
            folderPath = firstItem.pathToParent

            if firstItem.type == .folder {
                folderPath.append(firstItem)
            }

        } else {
            // MARK: Step backwards until we find an initial folder with a selectable item.

            var folderPointer =
                sourceItem.type == .folder
                ? sourceItem
                : sourceItem.parent!

            while !folderPointer.containsType(
                sourceItem.type,
                excluding: selectedIds,
                skipId: sourceItem.stableId
            ),
                let parent = folderPointer.parent
            {
                folderPointer = parent
            }

            folderPath = folderPointer.pathToParent

            if folderPointer.type == .folder {
                folderPath.append(folderPointer)
            }
        }

        _destinationItem = State(initialValue: destinationItem)
        _folderPath = State(initialValue: folderPath)
    }

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.showToast) private var showToast
    @EnvironmentObject private var listEngine: ListEngine<ChecklistItem>

    @State private var destinationItem: ChecklistItem?

    @State private var folderPath = NavigationPath()

    private var canSave: Bool {
        destinationItem != nil && destinationItem !== sourceItem
    }

    private var transferCount: LocalizedStringKey {
        "^[\(listEngine.selectedItems.count) item](inflect: true)"
    }

    // MARK: - Body

    var body: some View {
        NavigationStack(path: $folderPath) {
            FolderItemOptionsListView(
                destinationItem: $destinationItem,
                folderPath: $folderPath,
                folder: rootFolder,
                sourceItem: sourceItem
            )
            .toolbar {
                cancelButton
                submitButton
            }
            .navigationDestination(for: ChecklistItem.self) { folder in
                FolderItemOptionsListView(
                    destinationItem: $destinationItem,
                    folderPath: $folderPath,
                    folder: folder,
                    sourceItem: sourceItem
                )
                .toolbar {
                    cancelButton
                    submitButton
                }
            }
        }
        .background(Color.sheetBackground.ignoresSafeArea())
        .safeAreaInset(edge: .top) {
            customHeader
        }
    }

    // MARK: - Toolbars

    @ToolbarContentBuilder
    private var cancelButton: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            CancelButtonView {
                dismiss()
            }
        }
    }

    @ToolbarContentBuilder
    private var submitButton: some ToolbarContent {
        FormSaveButtonView(canSave: canSave, save: transferItems)
    }

    // MARK: - View Builders

    private var customHeader: some View {
        VStack(spacing: 20) {
            SheetTitle("Transfer Items")
            transferIndicator
        }
    }

    private var transferIndicator: some View {
        HStack(spacing: 8) {
            sourceChip

            if let destinationItem, destinationItem !== sourceItem {
                Image(systemName: "arrow.right")
                    .imageScale(.small)
                    .foregroundStyle(Color.secondary)

                destinationChip(destinationItem)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
    }

    private var sourceChip: some View {
        LabelValueView(
            title: sourceItem.title,
            subtitle: transferCount,
            iconConfig: IconConfig(
                name: sourceItem.type.systemImageName,
                primaryColor: sourceItem.color.swiftUIColor,
                secondaryColor: sourceItem.color.swiftUIColor
            )
        )
        .glassChip(height: 46)
    }

    private func destinationChip(_ destinationItem: ChecklistItem) -> some View
    {
        LabelValueView(
            title: destinationItem.title,
            iconConfig: IconConfig(
                name: destinationItem.type.systemImageName,
                primaryColor: destinationItem.color.swiftUIColor,
                secondaryColor: destinationItem.color.swiftUIColor
            )
        )
        .glassChip(height: 40)
    }

    // MARK: - Functions

    private func transferItems() {
        guard canSave, let destinationItem
        else {
            return
        }

        modelContext.transferChecklistItems(
            listEngine.selectedItems,
            into: destinationItem
        )

        dismiss()

        DispatchQueue.main.async {
            let selectedItemsTypeLabel = checklistItemsTypeLabel(
                listEngine.selectedItems
            )
            let itemCount = listEngine.selectedItems.count

            listEngine.toggleSelectMode()

            DispatchQueue.main.async {
                showNotification(
                    destinationItem: destinationItem,
                    itemCount: itemCount,
                    selectedItemsTypeLabel: selectedItemsTypeLabel
                )
            }
        }
    }

    private func showNotification(
        destinationItem: ChecklistItem,
        itemCount: Int,
        selectedItemsTypeLabel: String
    ) {
        let icon =
            sourceItem.type == .checklist
            ? "arrow.left.arrow.right" : "arrow.forward.folder"

        let variant: ToastPositionVariant =
            sourceItem.type == .folder ? .tab : .cover

        showToast(
            Toast(
                title:
                    "Successfully transferred ^[\(itemCount) \(selectedItemsTypeLabel)](inflect: true)!",
                subtitle: LocalizedStringKey(destinationItem.title),
                iconConfig: IconConfig(
                    name: icon,
                    primaryColor: Color.label,
                    secondaryColor: Color.label
                ),
                variant: variant,
                action: {
                    openItem(
                        destinationItem,
                        sourceItem.type == .folder
                            ? sourceItem : sourceItem.parent!
                    )
                }
            )
        )
    }
}
