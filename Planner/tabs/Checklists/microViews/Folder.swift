//
//  FolderView.swift
//  Planner
//
//  Created by Alex Green on 12/14/25.
//

import SwiftData
import SwiftUI

struct FolderView: View {
    let folder: ChecklistItem
    let openFolder: (ChecklistItem) -> Void
    let iconWidth: CGFloat = 26
    let rowSpacing: CGFloat = 12

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var checklistCoverId: PersistentIdentifier?
    @State private var pendingScrollItem: ChecklistItem?
    @Namespace private var namespace

    @State private var showDeleteSelectedConfirm = false
    @State private var showDeleteFolderConfirm = false
    @State private var showTransferSheet = false
    @State private var showCreateSheet = false
    @State private var showEditSheet = false

    @StateObject private var selectManager = ListManager<ChecklistItem>()

    var sortedItems: [ChecklistItem] {
        folder.items.sorted { $0.sortIndex < $1.sortIndex }
    }

    var isAllSelected: Bool {
        selectManager.selectedItemIds.count == sortedItems.count
    }

    private var navigationSubtitle: String {
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
            .navigationSubtitle(navigationSubtitle)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                topLeftToolbar
                topRightToolbar
            }

            // Create Item Form
            .sheet(isPresented: $showCreateSheet) {
                ChecklistItemFormView(item: nil, parent: folder) { id in
                    pendingScrollItem = id
                }
                .navigationTransition(
                    .zoom(sourceID: "ADD_BUTTON", in: namespace)
                )
            }

            // Edit Form
            .sheet(isPresented: $showEditSheet) {
                ChecklistItemFormView(item: folder, parent: folder.parent)
                    .navigationTransition(
                        .zoom(sourceID: "ELLIPSIS", in: namespace)
                    )
            }

            // Transfer Form
            .sheet(isPresented: $showTransferSheet) {
                TransferItemsFormView(currentItem: folder)
                    .environmentObject(selectManager)
                    .navigationTransition(
                        .zoom(
                            sourceID: "TRANSFER",
                            in: namespace
                        )
                    )
            }

            // Checklist Page
            .fullScreenCover(item: $checklistCoverId) { checklistId in
                ChecklistView(checklistId: checklistId) {
                    checklistCoverId = nil
                }
                .navigationTransition(
                    .zoom(
                        sourceID: checklistId,
                        in: namespace
                    )
                )
            }

            // Scroll to new items.
            .onChange(of: sortedItems.map(\.id)) { _, _ in
                guard let item = pendingScrollItem else { return }

                DispatchQueue.main.async {
                    withAnimation {
                        proxy.scrollTo(item.id, anchor: .top)
                    }
                }

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

    // MARK: - Toolbars

    @ToolbarContentBuilder
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

    @ToolbarContentBuilder
    private var topRightToolbar: some ToolbarContent {
        Group {
            if !selectManager.isSelectMode {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showEditSheet = true
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
                    .matchedTransitionSource(id: "ELLIPSIS", in: namespace)
                    .confirmationDialog(
                        folder.deleteConfirmation,
                        isPresented: $showDeleteFolderConfirm,
                        titleVisibility: .visible
                    ) {
                        Button("Confirm", role: .destructive) {
                            deleteEntireFolder()
                        }
                    } message: {
                        Text(folder.deleteWarning)
                    }

                    Button("Add", systemImage: "plus") {
                        showCreateSheet = true
                    }
                    .matchedTransitionSource(
                        id: "ADD_BUTTON",
                        in: namespace
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
                        showTransferSheet = true
                    }
                    .matchedTransitionSource(
                        id: "TRANSFER",
                        in: namespace
                    )
                    .disabled(selectManager.selectedItemIds.isEmpty)
                }
            }
        }
    }

    // MARK: - Item Rows

    private func itemRow(_ item: ChecklistItem) -> some View {
        HStack(alignment: .top, spacing: rowSpacing) {
            HStack(spacing: selectManager.isSelectMode ? 16 : 0) {

                AccentToggleView(
                    isOn: selectManager.selectedItemIds.contains(
                        item.id
                    )
                ) {
                    selectManager.toggleItem(item)
                }
                .opacity(selectManager.isSelectMode ? 1 : 0)
                .frame(width: selectManager.isSelectMode ? 22 : 0)
                .allowsHitTesting(selectManager.isSelectMode)

                itemIcon(for: item)
            }
            .frame(height: 19)
            .matchedTransitionSource(
                id: item.id,
                in: namespace
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
            .easeInOut(duration: 0.3),
            value: selectManager.isSelectMode
        )
        .id(item.id)
        .alignmentGuide(.listRowSeparatorLeading) { _ in
            iconWidth + rowSpacing
        }
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
                checklistCoverId = item.id
            }
        }
        .matchedTransitionSource(
            id: item.id,
            in: namespace
        )
    }

    private func itemIcon(for item: ChecklistItem) -> some View {
        Image(
            systemName: item.type.iconName
        )
        .foregroundColor(item.color.swiftUIColor)
        .imageScale(.medium)
        .frame(
            width: iconWidth,
            height: 53,
            alignment: .center
        )
    }

    // MARK: - Helper Functions

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
