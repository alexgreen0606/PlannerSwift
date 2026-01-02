//
//  FolderView.swift
//  Planner
//
//  Created by Alex Green on 12/14/25.
//

import SwiftData
import SwiftUI

// TODO: slide to new items after creation

enum ChecklistItemSheetContext: Identifiable {
    case create
    case parent
    case edit(ChecklistItem)

    var id: String {
        switch self {
        case .parent: return "PARENT"
        case .create: return "CREATE"
        case .edit(let item): return String(describing: item.id)
        }
    }
}

struct FolderView: View {
    let folder: ChecklistItem

    @Environment(\.modelContext) private var modelContext
    
    @EnvironmentObject var navigationManager: NavigationManager
    
    @State private var sheetContext: ChecklistItemSheetContext?
    @Namespace private var sheetAnimation
    @State private var scrollProxy: ScrollViewProxy?

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
                            .font(.system(size: 17))
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(alignment: .center) {
                            Text("\(item.items.filter{!$0.isChecked}.count)")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Image(systemName: "chevron.right")
                                .foregroundColor(Color(uiColor: .tertiaryLabel))
                        }
                        .frame(height: 19)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        navigationManager.checklistsPath.append(item)
                    }
                }
                .onMove(perform: moveItem)
            }
            .navigationTitle(folder.title)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            sheetContext = .parent
                        } label: {
                            Text("Edit folder details")
                            Image(systemName: "pencil")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                    .matchedTransitionSource(id: "ellipsis", in: sheetAnimation)

                    Button("Add", systemImage: "plus") {
                        sheetContext = .create
                    }
                    .matchedTransitionSource(id: "add", in: sheetAnimation)
                }
            }
            .sheet(item: $sheetContext) { context in
                switch context {
                case .create:
                    ChecklistItemFormView(item: nil, parent: folder)
                        .presentationDetents([.height(250)])
                        .navigationTransition(
                            .zoom(sourceID: "add", in: sheetAnimation)
                        )

                case .edit(let item):
                    ChecklistItemFormView(item: item, parent: folder)
                        .presentationDetents([.height(250)])
                        .navigationTransition(
                            .zoom(
                                sourceID: String(describing: item.id),
                                in: sheetAnimation
                            )
                        )

                case .parent:
                    ChecklistItemFormView(item: folder, parent: folder.parent)
                        .presentationDetents([.height(250)])
                        .navigationTransition(
                            .zoom(sourceID: "ellipsis", in: sheetAnimation)
                        )
                }
            }
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
}
