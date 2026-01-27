//
//  FolderView.swift
//  Planner
//
//  Created by Alex Green on 12/14/25.
//

import SwiftData
import SwiftUI

struct ChecklistCoverContext: Identifiable {
    var checklistId: PersistentIdentifier
    var namespace: Namespace.ID

    var id: String {
        "\(checklistId)-\(namespace)"
    }
}

struct FolderView: View {
    let folder: ChecklistItem
    let openFolder: (ChecklistItem) -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var sheetContext: ChecklistItemSheetContext?
    @Namespace private var sheetAnimation
    @State private var showDeleteFolderConfirm = false
    @State private var checklistCoverContext: ChecklistCoverContext?
    @State private var pendingScrollItem: ChecklistItem?

    var sortedItems: [ChecklistItem] {
        folder.items.sorted { $0.sortIndex < $1.sortIndex }
    }

    var body: some View {
        ScrollViewReader { proxy in
            List {
                ForEach(
                    sortedItems,
                    id: \.self
                ) { item in
                    itemRow(item)
                }
                .onMove(perform: moveItem)
            }
            .navigationTitle(folder.title)
            .navigationSubtitle(folder.path)
            .toolbar {
                topRightToolbar
            }

            // Create/Edit Checklist Form
            .sheet(item: $sheetContext) { context in
                switch context {
                case .create:
                    ChecklistItemFormView(item: nil, parent: folder) { id in
                        pendingScrollItem = id
                    }
                    .presentationDetents([.height(250)])
                    .navigationTransition(
                        .zoom(sourceID: "add", in: sheetAnimation)
                    )

                case .edit(let item):
                    ChecklistItemFormView(item: item, parent: folder) { _ in }
                        .presentationDetents([.height(250)])
                        .navigationTransition(
                            .zoom(
                                sourceID: String(describing: item.id),
                                in: sheetAnimation
                            )
                        )

                case .parent:
                    ChecklistItemFormView(item: folder, parent: folder.parent) {
                        _ in
                    }
                    .presentationDetents([.height(250)])
                    .navigationTransition(
                        .zoom(sourceID: "ellipsis", in: sheetAnimation)
                    )
                }
            }

            // Checklist Page
            .fullScreenCover(item: $checklistCoverContext) { context in
                ChecklistView(checklistId: context.checklistId) {
                    checklistCoverContext = nil
                }
                .navigationTransition(
                    .zoom(
                        sourceID: "\(context.checklistId)-\(context.namespace)",
                        in: context.namespace
                    )
                )
            }

            // Scroll to new items.
            .onChange(of: sortedItems.map(\.id)) { _, _ in
                guard let item = pendingScrollItem else { return }

                proxy.slideTo(item.id, at: .top)
                pendingScrollItem = nil
            }
        }

        // Empty Folder Label
        .overlay {
            if folder.items.isEmpty {
                EmptyLabel("No contents")
            }
        }
    }

    private func itemRow(_ item: ChecklistItem) -> some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading) {
                Image(systemName: item.type.iconName)
                    .foregroundColor(item.color.swiftUIColor)
                    .imageScale(.medium)
                    .frame(
                        width: 26,
                        height: 53,
                        alignment: .center
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        sheetContext = .edit(item)
                    }

            }
            .frame(height: 19)
            .matchedTransitionSource(
                id: String(describing: item.id),
                in: sheetAnimation
            )

            Text(item.title)
                .font(.system(size: UIConstants.listItemFontSize))
                .lineLimit(nil)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(alignment: .center) {
                Text("\(item.items.filter{!$0.isChecked}.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if item.type == .folder {
                    Image(systemName: "chevron.right")
                        .foregroundColor(
                            Color(uiColor: .tertiaryLabel)
                        )
                }
            }
            .frame(height: 19)
        }
        .id(item.id)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture {
            if item.type == .folder {
                openFolder(item)
            } else {
                checklistCoverContext = ChecklistCoverContext(
                    checklistId: item.id,
                    namespace: sheetAnimation
                )
            }
        }
        .matchedTransitionSource(
            id: "\(item.id)-\(sheetAnimation)",
            in: sheetAnimation
        )
    }

    private var topRightToolbar: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            Menu {
                Button {
                    sheetContext = .parent
                } label: {
                    Text("Edit folder details")
                    Image(systemName: "pencil")
                }

                if folder.parent != nil {
                    Button(role: .destructive) {
                        showDeleteFolderConfirm = true
                    } label: {
                        Text("Delete this folder")
                        Image(systemName: "trash")
                    }
                }

            } label: {
                Image(systemName: "ellipsis")
            }
            .matchedTransitionSource(id: "ellipsis", in: sheetAnimation)
            .confirmationDialog(
                folder.deleteConfirmation,
                isPresented: $showDeleteFolderConfirm,
                titleVisibility: .visible
            ) {
                Button("Confirm", role: .destructive) {
                    deleteEntireFolder()
                }
            } message: {
                Text(
                    folder.deleteWarning
                )
            }

            Button("Add", systemImage: "plus") {
                sheetContext = .create
            }
            .matchedTransitionSource(id: "add", in: sheetAnimation)
        }
    }

    private func moveItem(from sources: IndexSet, to destination: Int) {
        for source in sources {
            var targetIndex = destination
            if targetIndex > source {
                targetIndex -= 1
            }

            guard source != targetIndex else { continue }

            let movedEvent = sortedItems[source]
            let remainingItems = sortedItems.filter { $0.id != movedEvent.id }
            movedEvent.sortIndex = generateSortIndex(
                index: targetIndex,
                items: remainingItems
            )
        }

        try! modelContext.save()
    }

    private func deleteEntireFolder() {
        dismiss()

        modelContext.delete(folder)

        do {
            try modelContext.save()
        } catch {
            assertionFailure(
                "Failed to delete folder: \(error)"
            )
        }
    }
}
