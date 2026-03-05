//
//  ChecklistsTab.swift
//  Planner
//
//  Created by Alex Green on 12/14/25.
//

import SwiftData
import SwiftDate
import SwiftUI

// Clean

struct ChecklistsTabView: View {

    // Only one item should exist without a parent.
    @Query(
        filter: #Predicate<ChecklistItem> { item in
            item.parent == nil
        }
    ) var rootFolderList: [ChecklistItem]

    @StateObject private var checklistsManager = ListManager<ChecklistItem>()
    @State private var folderPath = NavigationPath()
    @State private var checklistCoverId: IdentifiableUuid?

    // Considers the selected items and whether any destination items exist to house them.
    @State private var canTransferChecklistItems: Bool = false
    @State private var canTransferFolderItems: Bool = false

    @Namespace private var namespace

    private var rootFolder: ChecklistItem? {
        rootFolderList.first
    }

    var body: some View {
        NavigationStack(path: $folderPath) {
            if let root = rootFolder {
                FolderView(
                    folder: root,
                    namespace: namespace,
                    openItem: openItem,
                    canTranferItems: canTransferFolderItems,
                    updateTransferAvailability: updateFolderTransferAvailability
                )
                .navigationDestination(for: ChecklistItem.self) { item in
                    if item.type == .folder {
                        FolderView(
                            folder: item,
                            namespace: namespace,
                            openItem: openItem,
                            canTranferItems: canTransferFolderItems,
                            updateTransferAvailability:
                                updateFolderTransferAvailability
                        )
                    }
                }
            }
        }

        // Checklist Cover
        .fullScreenCover(item: $checklistCoverId) { checklistId in
            ChecklistBuilderView(
                checklistId: checklistId.id,
                canTransferItems: canTransferChecklistItems
            ) { folderToOpen in
                checklistCoverId = nil

                if let folderToOpen {
                    openItem(folderToOpen)
                }
            }
            .navigationTransition(
                .zoom(
                    sourceID: checklistId.id,
                    in: namespace
                )
            )
            .environmentObject(checklistsManager)
        }
    }

    private func openItem(_ item: ChecklistItem) {
        if item.type == .folder {
            canTransferFolderItems =
                rootFolder?.hasChildType(.folder, excluding: Set([item.stableId]))
                == true
            folderPath.append(item)
        } else {
            canTransferChecklistItems =
                rootFolder?.hasChildType(.checklist, excluding: Set([item.stableId]))
                == true
            checklistCoverId = IdentifiableUuid(id: item.stableId)
        }
    }

    private func updateFolderTransferAvailability(
        considering itemIds: Set<UUID> // Includes: items to transfer + their current folder
    ) {
        canTransferFolderItems =
            rootFolder?.hasChildType(.folder, excluding: itemIds) == true
    }

}
