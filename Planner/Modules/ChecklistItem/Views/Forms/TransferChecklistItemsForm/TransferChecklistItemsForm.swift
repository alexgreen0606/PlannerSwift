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
        openItem: @escaping (ChecklistItem, ChecklistItem) -> Void
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
                _selectedItem = State(
                    initialValue: selectableFolders.first!
                )
            }
        }

        currentFolder = folderPointer
        self.destinationType = destinationType
    }

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @Environment(\.showToast) private var showToast
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var ListEngine: ListEngine<ChecklistItem>

    @State private var destinationType: ChecklistItemType
    @State private var selectedItem: ChecklistItem?
    @State private var currentFolder: ChecklistItem

    /// Controls the animation of the folder navigator.
    @State private var folderNavDirection: FolderNavigationDirection = .forward

    private var transferCount: LocalizedStringKey {
        let count = ListEngine.selectedItems.count
        return
            "^[\(count) item](inflect: true)"
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
        .animateUserAction(from: selectedItem?.stableId)
    }

    private var sourceChip: some View {
        TransferSelectionIndicatorView(
            title: source.title,
            subtitle: transferCount,
            iconConfig: IconConfig(
                name: source.type.systemImageName,
                primaryColor: source.color.swiftUIColor,
                secondaryColor: source.color.swiftUIColor
            )
        )
        .glassChip(height: 46)
    }

    private func destinationChip(_ selectedItem: ChecklistItem) -> some View {
        TransferSelectionIndicatorView(
            title: selectedItem.title,
            iconConfig: IconConfig(
                name: selectedItem.type.systemImageName,
                primaryColor: selectedItem.color.swiftUIColor,
                secondaryColor: selectedItem.color.swiftUIColor
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

        let selectedType = checklistItemsType(ListEngine.selectedItems)
        let itemCount = ListEngine.selectedItemIds.count

        modelContext.transferChecklistItems(
            ListEngine.selectedItems,
            into: selectedItem
        )

        ListEngine.toggleSelectMode()

        dismiss()

        let icon =
            source.type == .checklist
                ? "arrow.left.arrow.right" : "arrow.forward.folder"

        let variant: ToastVariant = source.type == .folder ? .tab : .cover

        showToast(
            Toast(
                title:
                "Successfully transferred ^[\(itemCount) \(selectedType)](inflect: true)!",
                subtitle: LocalizedStringKey(selectedItem.title),
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
