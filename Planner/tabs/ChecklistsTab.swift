//
//  ChecklistsTabView.swift
//  Planner
//
//  Created by Alex Green on 12/14/25.
//

import SwiftData
import SwiftDate
import SwiftUI

struct IdentifiableUUID: Identifiable {
    let id: UUID
}

struct ChecklistsTabView: View {

    @Environment(\.modelContext) private var modelContext

    @Query(
        filter: #Predicate<ChecklistItem> { item in
            item.parent == nil
        }
    ) var rootFolderList: [ChecklistItem] // Only one item should exist without a parent.

    @StateObject private var checklistsManager = ListManager<ChecklistItem>()
    @State private var folderPath = NavigationPath()
    @State private var checklistCoverId: IdentifiableUUID?

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

        // Checklist Page
        .fullScreenCover(item: $checklistCoverId) { checklistId in
            ChecklistBuilderView(
                checklistId: checklistId.id,
                canTransferItems: canTransferChecklistItems
            ) { newFolder in
                checklistCoverId = nil

                if let newFolder {
                    openItem(newFolder)
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
            checklistCoverId = IdentifiableUUID(id: item.stableId)
        }
    }

    // itemIds includes the items to transfer AND their current folder.
    private func updateFolderTransferAvailability(
        considering itemIds: Set<UUID>
    ) {
        canTransferFolderItems =
            rootFolder?.hasChildType(.folder, excluding: itemIds) == true
    }

}
