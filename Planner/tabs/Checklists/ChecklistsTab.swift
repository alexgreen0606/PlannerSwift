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

    private var root: ChecklistItem? {
        rootFolders.first
    }

    var body: some View {
        NavigationStack(path: $folderPath) {
            if let root = root {
                FolderView(folder: root, openFolder: openFolder)
                    .navigationDestination(for: ChecklistItem.self) { item in
                        if item.type == .folder {
                            FolderView(folder: item, openFolder: openFolder)
                        }
                    }
            }
        }
        .environmentObject(checklistsManager)
        .task {
            modelContext.ensureRootFolder(rootFolders: rootFolders)
        }
    }

    private func openFolder(folder: ChecklistItem) {
        folderPath.append(folder)
    }
}
