//
//  CurrentFolderList.swift
//  Planner
//
//  Created by Alex Green on 3/10/26.
//

import SwiftUI

struct CurrentFolderListView: View {
    @Binding var selectedItem: ChecklistItem?
    @Binding var currentFolder: ChecklistItem
    @Binding var folderNavDirection: FolderNavigationDirection
    let source: ChecklistItem
    let destinationType: ChecklistItemType

    @EnvironmentObject private var listManager: ListManager<ChecklistItem>

    @State private var selectableItems: [ChecklistItem] = []

    private var folderSlideTransition: AnyTransition {
        switch folderNavDirection {
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

    var body: some View {
        List {
            Section {
                ForEach(selectableItems, id: \.stableId, content: row)
            } header: {
                folderLabel
            }
            .listSectionMargins(.top, 0)
        }
        .id(currentFolder.stableId)
        .transition(folderSlideTransition)
        .overlay {
            if selectableItems.isEmpty {
                EmptyLabelView(
                    "No available \(destinationType.rawValue)s"
                )
            }
        }
        .task(id: currentFolder) {
            buildSelectableItems()
        }
    }

    // MARK: - View Builders

    private var folderLabel: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let parent = currentFolder.parent {
                ActionButtonView(
                    label: parent.title,
                    systemImage: "chevron.left"
                ) {
                    folderNavDirection = .backward

                    withAnimation {
                        currentFolder = parent
                    }

                    if destinationType == .folder {
                        // Select the folder we are navigating back to.
                        selectedItem = parent
                    }
                }
            }

            Text(currentFolder.title)
        }
    }

    private func row(for item: ChecklistItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading) {
                Image(
                    systemName: item.type.systemImageName
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
                .font(.system(size: ListLayout.FONT_SIZE))
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
            if item.type == .checklist || destinationType == .folder {
                selectedItem = item

                if item.type == .checklist { return }
            }

            folderNavDirection = .forward

            withAnimation {
                currentFolder = item
            }
        }
    }

    // MARK: - Functions

    private func buildSelectableItems() {
        selectableItems = currentFolder.safeItems
            .filter { item in
                if item.stableId == source.stableId {
                    if destinationType == .folder, item.type == .folder,
                        item.hasChildType(
                            .folder,
                            excluding: listManager.selectedItemIds
                        )
                    {
                        // This it the source. BUT we are looking for folders and this source contains a folder. Display it.
                        return true
                    }
                    return false
                }

                guard
                    !listManager.selectedItemIds
                        .contains(
                            item.stableId
                        )
                else { return false }

                if destinationType == .folder {
                    // Onlt show folders when selecting folders.
                    return item.type == .folder
                }

                if destinationType == .checklist, item.type == .folder {
                    // Only show folders when selecting checklists IF the folder contains a checklist.
                    return item.hasChildType(
                        .checklist,
                        excluding: Set([source.stableId])
                    )
                }

                return true
            }
            .sorted { $0.sortIndex < $1.sortIndex }
    }

}
