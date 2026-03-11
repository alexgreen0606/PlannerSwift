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
    let openItem: (ChecklistItem) -> Void
    let updateTransferAvailability: (Set<UUID>) -> Void

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

    @Environment(\.modelContext) private var modelContext

    @StateObject private var selectManager = ListManager<ChecklistItem>()

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
            HStack(spacing: selectManager.isSelectMode ? 16 : 0) {

                ListItemToggleView(
                    item: item,
                    tint: accentColor.color,
                    isChecked: selectManager.selectedItemIds.contains(
                        item.stableId
                    ),
                    opacity: selectManager.isSelectMode ? 1 : 0
                )
                .frame(width: selectManager.isSelectMode ? 22 : 0)
                .allowsHitTesting(selectManager.isSelectMode)

                itemIcon(for: item)
            }
            .frame(height: 19)

            Text(item.title)
                .font(.system(size: UiConstants.listItemFontSize))
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .center) {
                Text("\(item.items.filter{!$0.isChecked}.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if item.type == .folder {
                    Image(systemName: "chevron.right")
                        .foregroundColor(
                            Color(uiColor: .tertiaryLabel)
                        )
                }
            }
            .frame(height: 19)
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
            if selectManager.isSelectMode {
                selectManager.toggleItem(item)
                updateTransferAvailability(
                    Set(selectManager.selectedItemIds + [folder.stableId])
                )
                return
            }

            openItem(item)
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
            var targetIndex = destination
            if targetIndex > from {
                targetIndex -= 1
            }

            modelContext.moveChecklistItem(
                in: sortedItems,
                from: from,
                to: targetIndex
            )
        }
    }

}
