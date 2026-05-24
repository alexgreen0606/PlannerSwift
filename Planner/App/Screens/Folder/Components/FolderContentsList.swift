//
//  FolderContentsList.swift
//  Planner
//
//  Created by Alex Green on 3/10/26.
//

import SwiftData
import SwiftUI

struct FolderContentsListView: View {
    let folder: ChecklistItem
    let sortedItems: [ChecklistItem]
    let namespace: Namespace.ID
    let openItem: (ChecklistItem, ChecklistItem) -> Void

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var itemSelectEngine: ListEngine<ChecklistItem>

    // MARK: - Body

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
                spacing: itemSelectEngine.isSelectMode
                    ? FolderLayout.TOGGLE_SPACING : 0
            ) {
                // MARK: Toggle
                ListItemToggleView(
                    item: item,
                    opacity: itemSelectEngine.isSelectMode ? 1 : 0
                )
                .frame(
                    width: itemSelectEngine.isSelectMode
                        ? FolderLayout.TOGGLE_WIDTH : 0
                )
                .allowsHitTesting(itemSelectEngine.isSelectMode)

                // MARK: Icon
                Image(
                    systemName: item.type.systemImageName
                )
                .imageScale(.medium)
                .foregroundColor(item.color.swiftUIColor)
                .frame(
                    width: FolderLayout.ICON_WIDTH,
                    height: FolderLayout.ICON_CONTAINER_HEIGHT
                )
            }
            .frame(height: FolderLayout.ADORNMENT_HEIGHT)

            // MARK: Title
            Text(item.title)
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .font(.system(size: ListLayout.FONT_SIZE))
                .frame(maxWidth: .infinity, alignment: .leading)

            // MARK: End Adornment
            Group {
                if item.type == .checklist {
                    Text("\(item.safeItems.filter { !$0.isCompleted }.count)")
                } else {
                    Image(systemName: "chevron.right")
                }
            }
            .font(.caption)
            .foregroundStyle(Color.secondary)
            .frame(height: FolderLayout.ADORNMENT_HEIGHT)
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

    // MARK: - Functions

    private func moveItem(from sources: IndexSet, to destination: Int) {
        guard let from = sources.first else { return }

        modelContext.moveChecklistItem(
            in: sortedItems,
            from: from,
            to: destination
        )
    }

    private func handleTap(of item: ChecklistItem) {
        if itemSelectEngine.isSelectMode {
            itemSelectEngine.toggleItem(item)
            return
        }

        openItem(item, folder)
    }
}
