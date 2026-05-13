//
//  TransferChecklistItemsForm.swift
//  Planner
//
//  Created by Alex Green on 1/26/26.
//

import SwiftData
import SwiftUI

enum FolderNavigationDirection {
    case forward
    case backward
}

struct TransferChecklistItemsFormView: View {
    private let source: ChecklistItem
    private let openItem: (ChecklistItem, ChecklistItem) -> Void

    init(
        source: ChecklistItem,
        selectedIds: Set<UUID>,
        rootFolder: ChecklistItem,
        openItem: @escaping (ChecklistItem, ChecklistItem) -> Void,
    ) {
        self.source = source
        self.openItem = openItem

        var folderPointer =
            source.type == .folder
            ? source
            : source.parent!

        let excludedOptions = Set(selectedIds + [source.stableId])

        // Step backwards through folders until you find one with a selectable item.
        while !folderPointer.hasChildType(
            source.type,
            excluding: excludedOptions
        ),
            let parent = folderPointer.parent
        {
            folderPointer = parent
        }

        let destinationType: ChecklistItemType =
            source.type == .folder ? .folder : .checklist

        if destinationType == .folder {
            let selectableFolders = rootFolder.folders(
                excluding: excludedOptions
            )

            if selectableFolders.count == 1 {
                // Looking for folders and there's only one available. Automatically select it.
                self._selectedItem = State(
                    initialValue: selectableFolders.first!
                )
            }
        }

        self.currentFolder = folderPointer
        self.destinationType = destinationType
    }

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @Environment(\.showToast) private var showToast
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var ListStore: ListStore<ChecklistItem>

    @State private var destinationType: ChecklistItemType
    @State private var selectedItem: ChecklistItem?
    @State private var currentFolder: ChecklistItem

    // Controls the animation of the folder navigator.
    @State private var folderNavDirection: FolderNavigationDirection = .forward

    private var transferCount: String {
        let count = ListStore.selectedItems.count
        return
            "\(String(count)) item\(count == 1 ? "" : "s")"
    }

    private var canSave: Bool {
        guard let selectedItem else {
            return false
        }

        return selectedItem.stableId != source.stableId
    }

    var body: some View {
        NavigationStack {
            ZStack {
                CurrentFolderListView(
                    selectedItem: $selectedItem,
                    currentFolder: $currentFolder,
                    folderNavDirection: $folderNavDirection,
                    source: source,
                    destinationType: destinationType
                )
            }
            .navigationTitle(
                "Transfer Items"
            )
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                cancelButton
                submitButton
            }
            .safeAreaInset(edge: .top) {
                transferIndicator
            }
        }
        .background(Color.sheetBackground.ignoresSafeArea())
    }

    // MARK: - Toolbars

    @ToolbarContentBuilder
    private var cancelButton: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel", systemImage: "xmark") {
                dismiss()
            }
        }
    }

    @ToolbarContentBuilder
    private var submitButton: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button(
                "Submit",
                systemImage: "checkmark",
                role: .confirm,
                action: transferItems
            )
            .tint(accentColor.color)
            .disabled(!canSave)
        }
    }

    // MARK: - View Builders

    private var transferIndicator: some View {
        HStack(spacing: 16) {
            sourceChip

            if let selectedItem, selectedItem != source {
                Image(systemName: "arrow.right")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
                    .foregroundStyle(Color.secondary)

                destinationChip(selectedItem)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .animateSynchronousAction(from: selectedItem?.stableId)
    }

    private var sourceChip: some View {
        TransferSourceIndicatorView(
            title: transferCount,
            subtitle: source.title,
            iconConfig: IconConfig(
                name: source.type.systemImageName,
                primaryColor: source.color.swiftUIColor.opacity(0.8)
            )
        )
        .glassChip(height: 36)
    }

    private func destinationChip(_ selectedItem: ChecklistItem) -> some View {
        TransferDestinationIndicatorView(
            title: selectedItem.title,
            iconConfig: IconConfig(
                name: selectedItem.type.systemImageName,
                primaryColor: selectedItem.color.swiftUIColor
            )
        )
        .glassChip(height: 40)
    }

    // MARK: - Functions

    private func transferItems() {
        guard let selectedItem, selectedItem.stableId != source.stableId
        else {
            return
        }

        let selectedType = checklistItemsType(ListStore.selectedItems)
        let itemCount = ListStore.selectedItemIds.count

        modelContext.transferChecklistItems(
            ListStore.selectedItems,
            into: selectedItem
        )

        ListStore.toggleSelectMode()

        dismiss()

        let icon =
            source.type == .checklist
            ? "arrow.left.arrow.right" : "arrow.forward.folder"

        let variant: ToastVariant = source.type == .folder ? .tab : .sheet

        showToast(
            Toast(
                title:
                    "Successfully transferred \(selectedType.pluralized(from: itemCount))!",
                subtitle: selectedItem.title,
                iconConfig: IconConfig(
                    name: icon,
                    primaryColor: Color.label,
                    secondaryColor: Color.label
                ),
                variant: variant,
                action: {
                    openItem(
                        selectedItem,
                        destinationType == .folder ? source : source.parent!
                    )
                }
            )
        )
    }

}
