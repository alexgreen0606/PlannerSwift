//
//  ChecklistsTabView.swift
//  Planner
//
//  Created by Alex Green on 12/14/25.
//

import SwiftData
import SwiftDate
import SwiftUI

struct ChecklistsTabView: View {
    
    @Environment(\.modelContext) private var modelContext
    
    @Query var foldersList: [ChecklistItem]

    @StateObject private var checklistsManager = ListManager<ChecklistItem>()
    @State private var folderPath = NavigationPath()
    @State private var checklistCoverId: PersistentIdentifier?

    // Considers the selected items and whether any destination items exist to house them.
    @State private var canTransferChecklistItems: Bool = false
    @State private var canTransferFolderItems: Bool = false

    @Namespace private var namespace

    // TODO: should I query for parent == nil?
    private var rootFolder: ChecklistItem? {
        foldersList.first
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
                            updateTransferAvailability: updateFolderTransferAvailability
                        )
                    }
                }
            }
        }

        // Checklist Page
        .fullScreenCover(item: $checklistCoverId) { checklistId in
            ChecklistView(
                checklistId: checklistId,
                canTransferItems: canTransferChecklistItems
            ) { newFolder in
                checklistCoverId = nil

                if let newFolder {
                    openItem(newFolder)
                }
            }
            .navigationTransition(
                .zoom(
                    sourceID: checklistId,
                    in: namespace
                )
            )
            .environmentObject(checklistsManager)
        }
    }

    private func openItem(_ item: ChecklistItem) {
        if item.type == .folder {
            canTransferFolderItems =
                rootFolder?.hasChildType(.folder, excluding: Set([item.id])) == true
            folderPath.append(item)
        } else {
            canTransferChecklistItems =
                rootFolder?.hasChildType(.checklist, excluding: Set([item.id]))
                == true
            checklistCoverId = item.id
        }
    }

    // itemIds includes the items to transfer AND their current folder.
    private func updateFolderTransferAvailability(considering itemIds: Set<PersistentIdentifier>) {
        canTransferFolderItems =
            rootFolder?.hasChildType(.folder, excluding: itemIds) == true
    }

}
