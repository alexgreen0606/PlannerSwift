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
    
    @EnvironmentObject var navigationManager: NavigationManager
    
    @StateObject private var checklistsManager = ListManager<ChecklistItem>()
    
    private var root: ChecklistItem? {
        rootFolders.first
    }

    var body: some View {
        NavigationStack(path: $navigationManager.checklistsPath) {
            if let root = root {
                FolderView(folder: root)
                    .navigationDestination(for: ChecklistItem.self) { item in
                        if item.type == ChecklistItemType.folder {
                            FolderView(folder: item)
                        } else {
                            ChecklistView(checklist: item)
                        }
                    }
            }
        }
        .environmentObject(checklistsManager)
        .task {
            modelContext.ensureRootFolder(rootFolders: rootFolders)
        }
    }
}
