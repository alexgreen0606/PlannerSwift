//
//  FolderView.swift
//  Planner
//
//  Created by Alex Green on 12/14/25.
//

import SwiftData
import SwiftDate
import SwiftUI

enum FormConfig: Identifiable {
    case add
    case edit(ChecklistItem)

    var id: String {
        switch self {
        case .add: return "add"
        case .edit(let item): return String(describing: item.id)
        }
    }
}

struct FolderView: View {
    let folder: ChecklistItem

    @Environment(\.modelContext) private var modelContext

    @Namespace private var nameSpace

    @State var navigationManager = NavigationManager.shared
    @State private var formConfig: FormConfig?
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
                                    formConfig = .edit(item)
                                }

                        }
                        .frame(height: 19)
                        .matchedTransitionSource(
                            id: String(describing: item.id),
                            in: nameSpace
                        )

                        Text(item.title)
                            .font(.system(size: 17))
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                        HStack(alignment: .center) {
                            Text("\(item.items.count)")
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
                .onMove(perform: handleMoveItem)
            }
            .navigationTitle(folder.title)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            formConfig = .edit(folder)
                        } label: {
                            Text("Edit folder details")
                            Image(systemName: "pencil")
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Add", systemImage: "plus") {
                        formConfig = .add
                    }
                    .matchedTransitionSource(id: "addButton", in: nameSpace)

                }
            }
            .sheet(item: $formConfig) { destination in
                switch destination {
                case .add:
                    ChecklistItemFormView(item: nil, parent: folder)
                        .presentationDetents([.height(250)])
                        .navigationTransition(
                            .zoom(sourceID: "addButton", in: nameSpace)
                        )

                case .edit(let item):
                    ChecklistItemFormView(item: item, parent: folder)
                        .presentationDetents([.height(250)])
                        .navigationTransition(
                            .zoom(
                                sourceID: String(describing: item.id),
                                in: nameSpace
                            )
                        )
                }
            }
        }
    }
    
    private func handleMoveItem(from sources: IndexSet, to destination: Int) {
        for source in sources {
            var targetIndex = destination
            if targetIndex > source {
                targetIndex -= 1
            }

            guard source != targetIndex else { continue }

            let movedEvent = sortedItems[source]
            let remainingItems = sortedItems.filter { $0.id != movedEvent.id }
            movedEvent.sortIndex = generateSortIndex(index: targetIndex, items: remainingItems)
        }

        try! modelContext.save()
    }

    // TODO: slide to new items
    private func slideTo(
        _ id: any Hashable,
        at anchor: UnitPoint,
        withDelay delay: DispatchTimeInterval = .seconds(0)
    ) {
        guard let proxy = scrollProxy
        else { return }
        DispatchQueue.main.asyncAfter(
            deadline: .now() + delay
        ) {
            withAnimation(.linear(duration: 2)) {
                proxy.scrollTo(id, anchor: anchor)
            }
        }
    }
}
