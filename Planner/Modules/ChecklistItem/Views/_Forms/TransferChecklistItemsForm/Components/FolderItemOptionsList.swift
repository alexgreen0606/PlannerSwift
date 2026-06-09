//
//  FolderItemOptionsList.swift
//  Planner
//
//  Created by Alex Green on 3/10/26.
//

import SwiftUI

struct FolderItemOptionsListView: View {
    @Binding var destinationItem: ChecklistItem?
    @Binding var folderPath: NavigationPath
    let folder: ChecklistItem
    let sourceItem: ChecklistItem

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var listEngine: ListEngine<ChecklistItem>

    @State private var options: [ChecklistItem] = []

    // MARK: - Body

    var body: some View {
        List {
            Section {
                ForEach(options, id: \.stableId, content: row)
            } header: {
                folderLabel
                    .padding(.top, Layout.TOOLBAR_HEIGHT)
            }
            .listSectionMargins(.top, 0)
        }
        .overlay {
            if options.isEmpty {
                EmptyLabel(
                    "No available \(sourceItem.type.rawValue)s"
                )
            }
        }
        .task(id: folder.stableId) {
            buildOptions()
        }
        .navigationBarBackButtonHidden(true)
    }

    // MARK: - View Builders

    private var folderLabel: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let parent = folder.parent {
                ActionButtonView(
                    label: parent.title,
                    systemImage: "chevron.left",
                    spacing: 2
                ) {
                    dismiss()

                    if sourceItem.type == .folder {
                        // Select the folder we are navigating back to.
                        withAnimation {
                            destinationItem = parent
                        }
                    }
                }
            }

            Text(folder.title)
        }
    }

    private func row(for item: ChecklistItem) -> some View {
        HStack(alignment: .top) {
            Group {
                // MARK: Icon

                Image(
                    systemName: item.type.systemImageName
                )
                .foregroundColor(item.color.swiftUIColor)
                .frame(height: FolderLayout.TYPE_ICON_CONTAINER_HEIGHT)

                // MARK: Title

                Text(item.title)
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .font(.system(size: ListLayout.FONT_SIZE))

            // MARK: End Adornment

            Group {
                if destinationItem == item {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.label)
                }

                if item.type == .folder {
                    Image(systemName: "chevron.right")
                        .foregroundColor(Color.secondary)
                }
            }
            .font(.caption)
            .frame(maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture {
            if item.type == .folder {
                folderPath.append(item)
            }

            if item.type == sourceItem.type {
                withAnimation {
                    destinationItem = item
                }
            }
        }
    }

    // MARK: - Functions

    private func buildOptions() {
        options = folder.safeItems.filter {
            $0.containsType(
                sourceItem.type,
                excluding: listEngine.selectedItemIds,
                skipId: sourceItem.stableId
            )
        }
        .sorted { $0.sortIndex < $1.sortIndex }
    }
}
