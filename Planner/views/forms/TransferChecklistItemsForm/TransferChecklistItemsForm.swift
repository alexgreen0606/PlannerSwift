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

// Clean

struct TransferChecklistItemsFormView: View {
    private let source: ChecklistItem

    init(source: ChecklistItem, selectedIds: Set<UUID>) {
        var folderPointer =
            source.type == .folder
            ? source
            : source.parent!

        // Step backwards through folders until you find one with a selectable item.
        while !folderPointer.hasChildType(
            source.type,
            excluding: Set(selectedIds + [source.stableId])
        ),
            let parent = folderPointer.parent
        {
            folderPointer = parent
        }

        self.currentFolder = folderPointer
        self.destinationType =
            source.type == .folder ? .folder : .checklist
        self.source = source
    }

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var listManager: ListManager<ChecklistItem>

    @State private var destinationType: ChecklistItemType
    @State private var selectedItem: ChecklistItem?
    @State private var currentFolder: ChecklistItem

    private var transferCount: String {
        let count = listManager.selectedItems.count
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
                    source: source,
                    destinationType: destinationType
                )
            }
            .navigationTitle(
                "Transfer \(destinationType.childrenLabel.capitalizedFirst)"
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
                name: source.type.iconName,
                primaryColor: source.color.swiftUIColor.opacity(0.8)
            )
        )
        .glassChip(height: 36)
    }

    private func destinationChip(_ selectedItem: ChecklistItem) -> some View {
        TransferDestinationIndicatorView(
            title: selectedItem.title,
            iconConfig: IconConfig(
                name: selectedItem.type.iconName,
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

        modelContext.transferChecklistItems(
            into: selectedItem,
            items: listManager.selectedItems
        )

        listManager.toggleSelectMode()
        dismiss()
    }

}
