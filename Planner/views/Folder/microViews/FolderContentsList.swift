//
//  FolderContentsList.swift
//  Planner
//
//  Created by Alex Green on 3/10/26.
//

import SwiftUI

// Clean

struct FolderContentsListView: View {
    let folder: ChecklistItem
    let sortedItems: [ChecklistItem]
    let namespace: Namespace.ID
    let openItem: (ChecklistItem, ChecklistItem) -> Void
    let updateTransferAvailability: (Set<UUID>) -> Void

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var selectManager: ListManager<ChecklistItem>

    var body: some View {
        List {
            ForEach(
                sortedItems,
                id: \.stableId,
                content: row
            )
            .onMove(perform: moveItem)
        }
    }

    // MARK: - View Builders

    private func row(for item: ChecklistItem) -> some View {
        HStack(alignment: .top, spacing: FolderLayout.ROW_SPACING) {
            HStack(
                spacing: selectManager.isSelectMode
                    ? FolderLayout.TOGGLE_SPACING : 0
            ) {

                ListItemToggleView(
                    item: item,
                    tint: accentColor.color,
                    isChecked: selectManager.selectedItemIds.contains(
                        item.stableId
                    ),
                    opacity: selectManager.isSelectMode ? 1 : 0
                )
                .frame(
                    width: selectManager.isSelectMode
                        ? FolderLayout.TOGGLE_WIDTH : 0
                )
                .allowsHitTesting(selectManager.isSelectMode)

                itemIcon(for: item)
            }
            .frame(height: FolderLayout.HORIZONTAL_ADORNMENT_HEIGHT)

            Text(item.title)
                .font(.system(size: ListLayout.FONT_SIZE))
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .center) {
                if item.type == .checklist {
                    Text("\(item.items.filter{!$0.isChecked}.count)")
                        .font(.caption)
                } else {
                    Image(systemName: "chevron.right")
                }
            }
            .frame(height: FolderLayout.HORIZONTAL_ADORNMENT_HEIGHT)
            .foregroundColor(.secondary)
        }
        .id(item.stableId)
        .alignmentGuide(.listRowSeparatorLeading) { _ in
            FolderLayout.ICON_WIDTH + FolderLayout.ROW_SPACING
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .matchedTransitionSource(
            id: item.stableId,
            in: namespace
        )
        .contentShape(Rectangle())
        .onTapGesture {
            handleTap(of: item)
        }
    }

    private func itemIcon(for item: ChecklistItem) -> some View {
        Image(
            systemName: item.type.iconName
        )
        .foregroundColor(item.color.swiftUIColor)
        .imageScale(.medium)
        .frame(
            width: FolderLayout.ICON_WIDTH,
            height: FolderLayout.ICON_CONTAINER_HEIGHT,
            alignment: .center
        )
    }

    // MARK: - Functions

    private func moveItem(from sources: IndexSet, to destination: Int) {
        for from in sources {
            modelContext.moveChecklistItem(
                in: sortedItems,
                from: from,
                to: destination
            )
        }
    }

    private func handleTap(of item: ChecklistItem) {
        if selectManager.isSelectMode {
            selectManager.toggleItem(item)
            updateTransferAvailability(
                Set(selectManager.selectedItemIds + [folder.stableId])
            )
            return
        }

        openItem(item, folder)
    }

}
