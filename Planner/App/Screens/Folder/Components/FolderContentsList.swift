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

    private let TOGGLE_WIDTH: CGFloat = 22
    private let TOGGLE_SPACING: CGFloat = 16

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var itemSelectEngine: ListEngine<ChecklistItem>

    private var isSelectMode: Bool {
        itemSelectEngine.isSelectMode
    }

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
        HStack(alignment: .top) {
            Group {
                HStack(
                    spacing: isSelectMode
                        ? TOGGLE_SPACING : 0
                ) {
                    // MARK: Toggle

                    ListItemToggleView(
                        item: item,
                        opacity: isSelectMode ? 1 : 0
                    )
                    .frame(
                        width: isSelectMode
                            ? TOGGLE_WIDTH : 0
                    )
                    .allowsHitTesting(isSelectMode)

                    // MARK: Icon

                    Image(
                        systemName: item.type.systemImageName
                    )
                    .foregroundColor(item.color.swiftUIColor)
                }
                .frame(height: FolderLayout.TYPE_ICON_CONTAINER_HEIGHT)

                // MARK: Title

                Text(item.title)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .font(.system(size: ListLayout.FONT_SIZE))

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
            .frame(maxHeight: .infinity)
        }
        .id(item.stableId)
        .frame(maxWidth: .infinity)
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
            initialIndex: from,
            targetIndex: destination,
            sortedItems: sortedItems
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
