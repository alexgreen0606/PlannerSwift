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
    let namespace: Namespace.ID
    let openItem: (ChecklistItem) -> Void
    let canTranferItems: Bool
    let updateTransferAvailability: (Set<PersistentIdentifier>) -> Void
    let iconWidth: CGFloat = 26
    let rowSpacing: CGFloat = 12

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var pendingScrollItem: ChecklistItem?
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
            .animateSynchronousAction(from: selectManager.isSelectMode)

            // Create Item Form
            .sheet(isPresented: $showCreateSheet) {
                ChecklistItemFormView(item: nil, parent: folder) { savedItem in
                    pendingScrollItem = savedItem
                }
                .navigationTransition(
                    .zoom(sourceID: "ADD_BUTTON", in: namespace)
                )
            }

            // Edit Form
            .sheet(isPresented: $showEditSheet) {
                ChecklistItemFormView(item: folder, parent: folder.parent) {
                    savedItem in
                    if savedItem.type == .checklist {
                        dismiss()
                        openItem(savedItem)
                    }
                }
                .navigationTransition(
                    .zoom(sourceID: "ELLIPSIS", in: namespace)
                )
            }

            // Transfer Form
            .sheet(isPresented: $showTransferSheet) {
                TransferChecklistItemsFormView(
                    source: folder,
                    selectedIds: selectManager.selectedItemIds
                )
                .environmentObject(selectManager)
                .navigationTransition(
                    .zoom(
                        sourceID: "TRANSFER",
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

    @ToolbarContentBuilder
    private var topRightToolbar: some ToolbarContent {
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
                DeleteSelectedButtonView(
                    itemsLabel: "contents",
                    disabled: selectManager.selectedItemIds.isEmpty,
                    warningMessage: nil
                ) {
                    withAnimation(.easeInOut) {
                        modelContext.deleteChecklistItems(
                            selectManager.selectedItems
                        )
                    }

                    DispatchQueue.main.asyncAfter(
                        deadline: .now() + .milliseconds(750)
                    ) {
                        withAnimation {
                            selectManager.toggleSelectMode()
                        }
                    }
                }
            }

            ToolbarSpacer(.fixed, placement: .topBarTrailing)

            ToolbarItem(placement: .topBarTrailing) {
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
                .disabled(
                    !canTranferItems || selectManager.selectedItemIds.isEmpty
                )
            }
        }
    }

    // MARK: - Item Rows

    private func itemRow(_ item: ChecklistItem) -> some View {
        HStack(alignment: .top, spacing: rowSpacing) {
            HStack(spacing: selectManager.isSelectMode ? 16 : 0) {

                ToggleView(
                    isOn: selectManager.selectedItemIds.contains(
                        item.id
                    ),
                    tint: nil,
                    opacity: selectManager.isSelectMode ? 1 : 0,
                ) {
                    selectManager.toggleItem(item)
                    updateTransferAvailability(
                        Set(selectManager.selectedItemIds + [folder.id])
                    )
                }
                .frame(width: selectManager.isSelectMode ? 22 : 0)
                .allowsHitTesting(selectManager.isSelectMode)

                itemIcon(for: item)
            }
            .frame(height: 19)

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
        .alignmentGuide(.listRowSeparatorLeading) { _ in
            iconWidth + rowSpacing
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture {
            if selectManager.isSelectMode {
                selectManager.toggleItem(item)
                updateTransferAvailability(
                    Set(selectManager.selectedItemIds + [folder.id])
                )
                return
            }

            openItem(item)
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
