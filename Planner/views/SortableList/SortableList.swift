//
//  SortableListView.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import Combine
import SwiftUI

class FocusController: ObservableObject {
    @Published var focusedId: ObjectIdentifier?
}

struct SortableListView<Item: ListItem, EndAdornment: View, FloatingInfo: View>: View {
    let uncheckedItems: [Item]
    let checkedItems: [Item]
    let toggleType: ListToggleType = .storage
    let disabledItemIds: Set<ObjectIdentifier> = []
    let floatingInfo: FloatingInfo?
    let endAdornment: ((_ item: Item) -> EndAdornment)?
    let customToggleConfig: CustomIconConfig?
    let checkedHeader: String
    let checkedFooter: String?
    let onCreateItem: (_ index: Int) -> Void
    let onTitleChange: (_ item: Item) -> Void
    let onMoveUncheckedItem: (_ from: Int, _ to: Int) -> Void
    
    @AppStorage("showChecked") var showChecked: Bool = false
    
    @Environment(\.colorScheme) private var colorScheme

    @EnvironmentObject var listManager: ListManager

    @StateObject var focusController = FocusController()

    var body: some View {
        List {
            Section {
                HStack {
                    floatingInfo
                }
                .opacity(0)
                .padding(.horizontal, 16)
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listSectionSeparator(.hidden)
            Section {
                NewItemTriggerView {
                    handleCreateItem(
                        baseId: uncheckedItems.first?.id,
                        offset: 0
                    )
                }
            }
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)
            .listSectionSeparator(.hidden)
            Section {
                ForEach(uncheckedItems, id: \.self) { item in
                    ItemView(
                        item: item,
                        toggleType: toggleType,
                        isSelectDisabled: disabledItemIds.contains(
                            item.id
                        ),
                        showUpperDivider: item.id == uncheckedItems.first?.id,
                        endAdornment: endAdornment,
                        customToggleConfig: customToggleConfig,
                        onCreateItem: handleCreateItem,
                        onTitleChange: onTitleChange,
                    )
                    .id(item.id)
                }
                .onMove(perform: handleMoveUncheckedItem)
            } footer: {
                NewItemTriggerView {
                    handleCreateLowerItem()
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .id("bottom")
            }

            // TODO: deselecting item and then focusing it loses focus after movement to new list
            if showChecked {
                Section{
                    ForEach(checkedItems, id: \.self) { item in
                        ItemView(
                            item: item,
                            toggleType: toggleType,
                            isSelectDisabled: disabledItemIds.contains(
                                item.id
                            ),
                            showUpperDivider: item.id
                            == checkedItems.first?.id,
                            endAdornment: endAdornment,
                            customToggleConfig: customToggleConfig,
                            onCreateItem: { _, _ in },
                            onTitleChange: { _ in },
                        )
                        .id(item.id)
                    }
                } header: {
                    Text(checkedHeader)
                } footer: {
                    if checkedFooter != nil {
                        Text(checkedFooter!)
                            .font(.footnote)
                            .foregroundStyle(Color(uiColor: .secondaryLabel))
                    }
                }
                .listRowBackground(Color.clear)
                .listSectionSeparator(.hidden)
                .id("checked")
            }
        }
        .environmentObject(focusController)
        .refreshable {}
        .overlay(alignment: .top) {
            floatingInfo
                .padding(.horizontal, 16)
        }
        .listStyle(.plain)
        .environment(\.defaultMinListRowHeight, 0)
        .animation(.linear(duration: 0.2), value: uncheckedItems)
        .safeAreaPadding(.bottom, 20)
        .background(Color.appBackground)
    }

    private func handleCreateItem(
        baseId: ObjectIdentifier?,
        offset: Int = 0
    ) {
        guard
            let baseIndex = uncheckedItems.firstIndex(where: {
                $0.id == baseId
            })
        else {
            return
        }
        
        let finalIndex = baseIndex + offset

        // Don't create the new item if it is next to an empty item.
        let upperEvent = finalIndex > 0 ? uncheckedItems[finalIndex - 1] : nil
        let lowerEvent =
            finalIndex < uncheckedItems.count ? uncheckedItems[finalIndex] : nil
        if let upper = upperEvent, upper.title.isEmpty {
            return
        }
        if let lower = lowerEvent, lower.title.isEmpty {
            return
        }

        onCreateItem(finalIndex)
    }

    private func handleMoveUncheckedItem(from sources: IndexSet, to destination: Int) {
        for source in sources {
            var to = destination

            if to > source {
                to -= 1
            }

            onMoveUncheckedItem(source, to)
        }
    }

    private func handleCreateLowerItem() {
        let baseId = uncheckedItems.last?.id
        handleCreateItem(baseId: baseId, offset: 1)
    }
}
