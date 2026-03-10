//
//  FolderView.swift
//  Planner
//
//  Created by Alex Green on 12/14/25.
//

import SwiftData
import SwiftUI

enum LayoutConstants {
    static let ICON_WIDTH: CGFloat = 26
    static let ROW_SPACING: CGFloat = 12
    static let ICON_CONTAINER_HEIGHT: CGFloat = 53
}

struct FolderView: View {
    let folder: ChecklistItem
    let namespace: Namespace.ID
    let openItem: (ChecklistItem) -> Void
    let canTranferItems: Bool
    let updateTransferAvailability: (Set<UUID>) -> Void

    @AppStorage("accentColor") var accentColor: AccentColor =
        AccentColor.blue

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
        ScrollViewReader { scrollProxy in
            List {
                ForEach(
                    sortedItems,
                    id: \.stableId
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
                ChecklistItemFormView(parent: folder) {
                    scrollToBottom(scrollProxy: scrollProxy)
                }
                .navigationTransition(
                    .zoom(sourceID: IdConstants.ADD_BUTTON, in: namespace)
                )
            }

            // Edit Form
            .sheet(isPresented: $showEditSheet) {
                ChecklistItemFormView(item: folder, parent: folder.parent)
                    .navigationTransition(
                        .zoom(
                            sourceID: IdConstants.ELLIPSIS_BUTTON,
                            in: namespace
                        )
                    )
            }

            // Transfer Form
            .sheet(isPresented: $showTransferSheet) {
                TransferChecklistItemsFormView(
                    source: folder,
                    selectedIds: selectManager.selectedItemIds
                )
                .navigationTransition(
                    .zoom(
                        sourceID: IdConstants.TRANSFER_BUTTON,
                        in: namespace
                    )
                )
            }

            // Scroll to new items.
            .onChange(of: sortedItems.map(\.stableId)) { _, _ in
                guard let item = pendingScrollItem else { return }

                DispatchQueue.main.async {
                    withAnimation {
                        scrollProxy.scrollTo(item.stableId, anchor: .top)
                    }
                }

                pendingScrollItem = nil
            }
        }

        // Empty Folder Label
        .overlay {
            if folder.items.isEmpty {
                EmptyLabelView(text: "No contents")
            }
        }
        .environmentObject(selectManager)
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
                    selectManager.toggleSelectAll(visibleItems: sortedItems)
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
                .matchedTransitionSource(
                    id: IdConstants.ELLIPSIS_BUTTON,
                    in: namespace
                )
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
                    id: IdConstants.ADD_BUTTON,
                    in: namespace
                )
            }
        } else {
            ToolbarItem(placement: .topBarTrailing) {
                DeleteSelectedButtonView(
                    itemsLabel: "contents",
                    disabled: selectManager.selectedItemIds.isEmpty,
                    message: nil
                ) {
                    withAnimation {
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
                    id: IdConstants.TRANSFER_BUTTON,
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
        HStack(alignment: .top, spacing: LayoutConstants.ROW_SPACING) {
            HStack(spacing: selectManager.isSelectMode ? 16 : 0) {

                ListItemToggleView(
                    item: item,
                    tint: accentColor.color,
                    isChecked: selectManager.selectedItemIds.contains(
                        item.stableId
                    ),
                    opacity: selectManager.isSelectMode ? 1 : 0
                )
                .frame(width: selectManager.isSelectMode ? 22 : 0)
                .allowsHitTesting(selectManager.isSelectMode)

                itemIcon(for: item)
            }
            .frame(height: 19)

            Text(item.title)
                .font(.system(size: UiConstants.listItemFontSize))
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
        .id(item.stableId)
        .alignmentGuide(.listRowSeparatorLeading) { _ in
            LayoutConstants.ICON_WIDTH + LayoutConstants.ROW_SPACING
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .contentShape(Rectangle())
        .onTapGesture {
            if selectManager.isSelectMode {
                selectManager.toggleItem(item)
                updateTransferAvailability(
                    Set(selectManager.selectedItemIds + [folder.stableId])
                )
                return
            }

            openItem(item)
        }
        .matchedTransitionSource(
            id: item.stableId,
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
            width: LayoutConstants.ICON_WIDTH,
            height: LayoutConstants.ICON_CONTAINER_HEIGHT,
            alignment: .center
        )
    }

    // MARK: - Helper Functions

    private func moveItem(from sources: IndexSet, to destination: Int) {
        for from in sources {
            var targetIndex = destination
            if targetIndex > from {
                targetIndex -= 1
            }

            modelContext.moveChecklistItem(
                in: sortedItems,
                from: from,
                to: targetIndex
            )
        }
    }

    private func deleteEntireFolder() {
        dismiss()
        modelContext.deleteChecklistItem(folder)
    }

    private func scrollToBottom(scrollProxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            withAnimation {
                scrollProxy.scrollTo(
                    IdConstants.UNCHECKED_ITEMS,
                    anchor: .bottom
                )
            }
        }
    }

}
