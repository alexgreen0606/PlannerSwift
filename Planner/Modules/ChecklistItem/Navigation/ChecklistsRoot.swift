//
//  ChecklistsRoot.swift
//  Planner
//
//  Created by Alex Green on 12/14/25.
//

import SwiftData
import SwiftDate
import SwiftUI

struct ChecklistsRootView: View {
    /// Only one item should exist without a parent.
    @Query(
        filter: #Predicate<ChecklistItem> { $0.parent == nil }
    ) var rootFolderList: [ChecklistItem]

    @State private var folderPath = NavigationPath()
    @State private var checklistCoverId: ChecklistCoverContext?

    @Namespace private var namespace

    private var rootFolder: ChecklistItem? {
        rootFolderList.first
    }

    var body: some View {
        if let rootFolder {
            NavigationStack(path: $folderPath) {
                ChecklistItemLoaderView(
                    stableId: rootFolder.stableId
                ) { context in
                    FolderRootView(
                        folder: context.item,
                        sortedItems: context.sortedItems,
                        rootFolder: rootFolder,
                        namespace: namespace,
                        openItem: openItem
                    )
                }
                .navigationDestination(for: ChecklistItem.self) { item in
                    if item.type == .folder {
                        ChecklistItemLoaderView(
                            stableId: item.stableId,
                        ) { context in
                            FolderRootView(
                                folder: context.item,
                                sortedItems: context.sortedItems,
                                rootFolder: rootFolder,
                                namespace: namespace,
                                openItem: openItem
                            )
                        }
                    }
                }
            }

            // MARK: Checklist Root

            .fullScreenCover(item: $checklistCoverId) { checklistId in
                ChecklistItemLoaderView(
                    stableId: checklistId.id
                ) { context in
                    ChecklistRootView(
                        checklist: context.item,
                        sortedItems: context.sortedItems,
                        rootFolder: rootFolder,
                        openItem: openItem
                    )
                }
                .navigationTransition(
                    .zoom(
                        sourceID: checklistId.id,
                        in: namespace
                    )
                )
                .id(checklistId.id)
                .interactiveDismissDisabled(true)
            }
        }
    }

    private func openItem(_ item: ChecklistItem, from source: ChecklistItem) {
        let isInCurrentFolder = source.safeItems.contains(where: {
            $0.stableId == item.stableId
        })

        if !isInCurrentFolder {
            buildPath(to: item)
        }

        if item.type == .folder {
            folderPath.append(item)
        } else {
            checklistCoverId = ChecklistCoverContext(id: item.stableId)
        }
    }

    private func buildPath(to item: ChecklistItem) {
        var reversePath: [ChecklistItem] = []

        guard let parent = item.parent else {
            return
        }

        var pointer = parent

        // Walk up to the root.
        while true {
            reversePath.append(pointer)

            guard let parent = pointer.parent else { break }
            pointer = parent
        }

        var path = NavigationPath()
        for folder in reversePath.reversed() {
            path.append(folder)
        }

        folderPath = path
    }
}
