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
    @Query var rootFolders: [ChecklistItem]

    @StateObject private var checklistsManager = ListManager<ChecklistItem>()
    @State private var folderPath = NavigationPath()
    @State private var checklistCoverId: PersistentIdentifier?
    
    @Namespace private var namespace

    private var root: ChecklistItem? {
        rootFolders.first
    }

    var body: some View {
        NavigationStack(path: $folderPath) {
            if let root = root {
                FolderView(folder: root, namespace: namespace, openItem: openItem)
                    .navigationDestination(for: ChecklistItem.self) { item in
                        if item.type == .folder {
                            FolderView(folder: item, namespace: namespace, openItem: openItem)
                        }
                    }
            }
        }
        
        // Checklist Page
        .fullScreenCover(item: $checklistCoverId) { checklistId in
            ChecklistView(checklistId: checklistId) { newFolder in
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
        
        .task {
            modelContext.ensureRootFolder(rootFolders: rootFolders)
        }
    }

    private func openItem(_ item: ChecklistItem) {
        if item.type == .folder {
            folderPath.append(item)
        } else {
            checklistCoverId = item.id
        }
    }

}
