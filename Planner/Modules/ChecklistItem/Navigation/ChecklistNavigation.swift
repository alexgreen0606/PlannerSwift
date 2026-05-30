//
//  ChecklistNavigation.swift
//  Planner
//
//  Created by Alex Green on 12/14/25.
//

import SwiftData
import SwiftUI

struct ChecklistNavigationView: View {
    /// Only one item should exist without a parent.
    @Query(
        filter: #Predicate<ChecklistItem> { $0.parent == nil }
    ) var rootFolders: [ChecklistItem]

    @State private var folderPath = NavigationPath()
    @State private var checklistCoverContext: ChecklistCoverContext?

    @Namespace private var namespace

    private var rootFolder: ChecklistItem? {
        rootFolders.first
    }

    // MARK: - Body

    var body: some View {
        if let rootFolder {
            ToastRootView {
                NavigationStack(path: $folderPath) {
                    
                    // MARK: Root Folder Root
                    
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
                                stableId: item.stableId
                            ) { context in
                                
                                // MARK: Folder Root
                                
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
                
                .fullScreenCover(item: $checklistCoverContext) { context in
                    ChecklistItemLoaderView(
                        stableId: context.id
                    ) { context in
                        ChecklistRootView(
                            checklist: context.item,
                            sortedItems: context.sortedItems,
                            rootFolder: rootFolder,
                            openItem: openItem
                        )
                    }
                    .id(context.id)
                    .navigationTransition(
                        .zoom(
                            sourceID: context.id,
                            in: namespace
                        )
                    )
                    .interactiveDismissDisabled(true)
                }
            }
        }
    }

    // MARK: - Functions

    private func openItem(_ item: ChecklistItem, from source: ChecklistItem) {
        let isInCurrentFolder = source.safeItems.contains(where: {
            $0.stableId == item.stableId
        })

        if !isInCurrentFolder {
            jumpToParent(of: item)
        }

        if item.type == .folder {
            folderPath.append(item)
        } else {
            checklistCoverContext = ChecklistCoverContext(id: item.stableId)
        }
    }

    private func jumpToParent(of item: ChecklistItem) {
        folderPath = item.path
    }
}
