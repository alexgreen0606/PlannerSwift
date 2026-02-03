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

    @State private var checklistCoverContext: ChecklistCoverContext?
    @Namespace private var sheetAnimation
    @State private var pendingScrollItem: ChecklistItem?

    @State private var showDeleteFolderConfirm = false
    @State private var showDeleteSelectedConfirm = false
    @State private var isTransferSheetOpen = false
    @State private var isCreateItemSheetOpen = false
    @State private var isEditFormOpen = false

    @StateObject private var selectManager = ListManager<ChecklistItem>()

    var sortedItems: [ChecklistItem] {
        folder.items.sorted { $0.sortIndex < $1.sortIndex }
    }

    var isAllSelected: Bool {
        selectManager.selectedItemIds.count == sortedItems.count
    }

    private var subtitle: String {
        if selectManager.isSelectMode {
            let count = selectManager.selectedItems.count
            return
                "\(count == 0 ? "No" : String(count)) items selected"
        }

        return folder.path
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
            .navigationSubtitle(subtitle)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                topLeftToolbar
                topRightToolbar
            }

            // Create Item Form
            .sheet(isPresented: $isCreateItemSheetOpen) {
                ChecklistItemFormView(item: nil, parent: folder) { id in
                    pendingScrollItem = id
                }
                .navigationTransition(
                    .zoom(sourceID: "ADD_BUTTON", in: sheetAnimation)
                )
            }

            // Edit Form
            .sheet(isPresented: $isEditFormOpen) {
                ChecklistItemFormView(item: folder, parent: folder.parent)
                .navigationTransition(
                    .zoom(sourceID: "ELLIPSIS", in: sheetAnimation)
                )
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

                proxy.scrollTo(item.id, anchor: .top)
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
            HStack(spacing: selectManager.isSelectMode ? 16 : 0) {

                Image(
                    systemName: selectManager.selectedItemIds.contains(
                        item.id
                    ) ? "circle.inset.filled" : "circle"
                )
                .foregroundStyle(
                    selectManager.selectedItemIds.contains(
                        item.id
                    )
                        ? folder.color.swiftUIColor
                        : Color(uiColor: .secondaryLabel)
                )
                .contentTransition(
                    .symbolEffect(
                        .replace
                    )
                )
                .imageScale(.large)
                .opacity(selectManager.isSelectMode ? 1 : 0)
                .frame(width: selectManager.isSelectMode ? 22 : 0)
                .allowsHitTesting(selectManager.isSelectMode)
                .contentShape(Circle())
                .onTapGesture {
                    selectManager.toggleItem(item)
                }

                itemIcon(for: item)
                    .opacity(selectManager.isSelectMode ? 0.5 : 1)
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
            .opacity(selectManager.isSelectMode ? 0 : 1)
        }
        .animation(
            .easeInOut(duration: 0.2),
            value: selectManager.isSelectMode
        )
        .id(item.id)
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture {
            if selectManager.isSelectMode {
                selectManager.toggleItem(item)
                return
            }

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

    private var topLeftToolbar: some ToolbarContent {
        Group {
            if !selectManager.isSelectMode {
                if folder.parent != nil {
                    ToolbarItemGroup(placement: .topBarLeading) {
                        Button("Back", systemImage: "chevron.left") {
                            dismiss()
                        }
                    }
                }
            } else {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close", systemImage: "xmark") {
                        selectManager.toggleSelectMode()
                    }
                }

                ToolbarSpacer(.fixed, placement: .topBarLeading)

                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        if isAllSelected {
                            selectManager.selectedItemIds = []
                            selectManager.selectedItems = []
                        } else {
                            selectManager.selectedItems = sortedItems
                            selectManager.selectedItemIds = Set(
                                sortedItems.map { $0.id }
                            )
                        }
                    } label: {
                        Text(isAllSelected ? "Deselect All" : "Select All")
                            .fontWeight(.semibold)
                    }
                    .disabled(sortedItems.isEmpty)
                }
            }
        }
    }

    private var topRightToolbar: some ToolbarContent {
        Group {
            if !selectManager.isSelectMode {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            isEditFormOpen = true
                        } label: {
                            Text("Edit folder details")
                            Image(systemName: "pencil")
                        }

                        Button {
                            selectManager.toggleSelectMode()
                        } label: {
                            Image(systemName: "checkmark.circle")
                            Text("Select contents")
                                .fontWeight(.semibold)
                        }
                        .disabled(sortedItems.isEmpty)

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
                    .matchedTransitionSource(id: "ELLIPSIS", in: sheetAnimation)
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
                        isCreateItemSheetOpen = true
                    }
                    .matchedTransitionSource(
                        id: "ADD_BUTTON",
                        in: sheetAnimation
                    )
                }
            } else {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Delete", systemImage: "trash") {
                        showDeleteSelectedConfirm = true
                    }
                    .disabled(selectManager.selectedItemIds.isEmpty)
                    .confirmationDialog(
                        "Delete selected contents?",
                        isPresented: $showDeleteSelectedConfirm,
                        titleVisibility: .visible
                    ) {
                        Button("Confirm", role: .destructive) {
                            withAnimation(.easeInOut) {
                                modelContext.deleteChecklistItems(
                                    selectManager.selectedItems
                                )
                            }

                            DispatchQueue.main.asyncAfter(
                                deadline: .now() + .milliseconds(750)
                            ) {
                                selectManager.toggleSelectMode()
                            }
                        }
                    } message: {
                        Text(
                            "This action is irreversible."
                        )
                    }
                }

                ToolbarSpacer(.fixed, placement: .topBarTrailing)

                ToolbarItem(placement: .topBarTrailing) {
                    // TODO: hide this if there are no other folders to transfer to
                    Button(
                        "Transfer",
                        systemImage: "arrow.forward.folder"
                    ) {
                        isTransferSheetOpen = true
                    }
                    .disabled(selectManager.selectedItemIds.isEmpty)
                    .sheet(isPresented: $isTransferSheetOpen) {
                        TransferItemsFormView(currentItem: folder)
                            .environmentObject(selectManager)
                    }
                }
            }
        }
    }

    private func itemIcon(for item: ChecklistItem) -> some View {
        Image(
            systemName: item.type.iconName
        )
        .foregroundColor(item.color.swiftUIColor)
        .imageScale(.medium)
        .frame(
            width: 26,
            height: 53,
            alignment: .center
        )
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
