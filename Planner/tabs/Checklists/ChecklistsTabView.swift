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

    let checklistsManager = ListManager()

    @State var navigationManager = NavigationManager.shared
    @State private var root: ChecklistItem?

    var body: some View {
        NavigationStack(path: $navigationManager.checklistsPath) {
            if let root = root {
                FolderView(folder: root)
                    .navigationDestination(for: ChecklistItem.self) { item in
                        if item.type == .folder {
                            FolderView(folder: item)
                        } else {
                            ChecklistView(checklist: item)
                        }
                    }
            }
        }
        .environmentObject(checklistsManager)
        .task {
            ensureRootFolder()
        }
    }

    @MainActor
    private func ensureRootFolder() {
        if let storageRoot = rootFolders.first {
            root = storageRoot
        } else if root == nil {
            // Only create if root folder doesn't exist yet.
            let newRoot = ChecklistItem(
                type: .folder,
                title: "Checklists",
                color: .label,
                sortIndex: 0
            )
            modelContext.insert(newRoot)
            try! modelContext.save()

            root = newRoot
        }
    }
}

#Preview {
    ChecklistsTabView()
}
