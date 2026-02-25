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

    init(source: ChecklistItem, selectedIds: Set<UUID>) {
        var fp =
            source.type == .folder
            ? source
            : source.parent!

        // Step backwards through folders until you find one with a selectable item.
        while !fp.hasChildType(
            source.type,
            excluding: Set(selectedIds + [source.stableId])
        ),
            let parent = fp.parent
        {
            fp = parent
        }

        self.currentFolder = fp

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
    @State private var destination: ChecklistItem?
    @State private var currentFolder: ChecklistItem

    // Controls the animation of the folder navigator.
    @State private var navDirection: FolderNavigationDirection = .forward

    private var transferCount: String {
        let count = listManager.selectedItems.count
        return
            "\(count == 0 ? "No" : String(count)) item\(count == 1 ? "" : "s")"
    }

    private var folderSlideTransition: AnyTransition {
        switch navDirection {
        case .forward:
            return .asymmetric(
                insertion: .move(edge: .trailing),
                removal: .move(edge: .leading)
            )
        case .backward:
            return .asymmetric(
                insertion: .move(edge: .leading),
                removal: .move(edge: .trailing)
            )
        }
    }

    var currentOptions: [ChecklistItem] {
        currentFolder.items
            .filter { item in
                guard
                    item.stableId != source.stableId
                        && !listManager.selectedItemIds
                            .contains(
                                item.stableId
                            )
                else { return false }

                // If in folder mode, only show folders.
                if destinationType == .folder {
                    return item.type == .folder
                }

                // If in checklist mode and item is a folder, only show if it has checklists.
                if destinationType == .checklist, item.type == .folder {
                    return item.hasChildType(
                        .checklist,
                        excluding: Set([source.stableId])
                    )
                }

                return true
            }
            .sorted { $0.sortIndex < $1.sortIndex }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                List {
                    Section {
                        ForEach(currentOptions, id: \.stableId) { item in
                            itemRow(item)
                        }
                    } header: {
                        folderLabel
                    }
                    .listSectionMargins(.top, 0)
                }
            }
            .id(currentFolder.stableId)
            .transition(folderSlideTransition)
            .overlay {
                if currentOptions.isEmpty {
                    EmptyLabel(
                        "No Available \(destinationType.rawValue.capitalizedFirst)s"
                    )
                }
            }
            .navigationTitle(
                "Transfer \(destinationType.childrenLabel.capitalizedFirst)"
            )
            .navigationBarTitleDisplayMode(.inline)
            .background(Color(.systemBackground))
            .toolbar {
                topRightToolbar
                topLeftToolbar
            }
            .safeAreaInset(edge: .top) {
                transferIndicator
            }
        }
    }

    // MARK: - Toolbars

    @ToolbarContentBuilder
    private var topLeftToolbar: some ToolbarContent {
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
                guard let destination, destination.stableId != source.stableId else {
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
            .disabled(destination == nil || destination!.stableId == source.stableId)
            .tint(accentColor.swiftUIColor)
        }
    }

    // MARK: - Transfer Indicator

    private var transferIndicator: some View {
        HStack(spacing: 16) {
            sourceChip

            if let destination {
                Image(systemName: "arrow.right")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
                    .foregroundStyle(Color.secondary)

                destinationChip(destination)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal)
        .animateSynchronousAction(from: destination?.stableId)
    }

    private var sourceChip: some View {
        TransferSourceIndicatorView(
            title: transferCount,
            subtitle: source.title,
            iconConfig: IconConfig(
                name: source.type.iconName,
                primaryColor: source.color.swiftUIColor.opacity(0.8),
                secondaryColor: nil
            )
        )
        .glassChip(color: nil, onTap: nil, height: 36)
    }

    private func destinationChip(_ selectedItem: ChecklistItem) -> some View {
        TransferDestinationIndicatorView(
            title: selectedItem.title,
            iconConfig: IconConfig(
                name: selectedItem.type.iconName,
                primaryColor: selectedItem.color.swiftUIColor,
                secondaryColor: nil
            )
        )
        .glassChip(color: nil, onTap: nil, height: 40)
    }

    // MARK: - Folder Contents

    private var folderLabel: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let parent = currentFolder.parent {
                AccentButtonView(
                    label: parent.title,
                    systemImage: "chevron.left"
                ) {
                    navDirection = .backward

                    withAnimation {
                        currentFolder = parent
                    }

                    if destinationType == .folder {
                        // Select the folder we are navigating back to.
                        destination = parent
                    }
                }
            }

            Text(currentFolder.title)
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

            if destination == item {
                Image(systemName: "checkmark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture {
            if item.type == .checklist || destinationType == .folder {
                destination = item

                if item.type == .checklist { return }
            }

            navDirection = .forward

            withAnimation {
                currentFolder = item
            }
        }
    }

}
