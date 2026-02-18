//
//  SortableListView.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import Combine
import SwiftData
import SwiftUI

class FocusController: ObservableObject {
    @Published var focusedId: PersistentIdentifier?
}

struct SortableListView<
    Item: ListItem,
    LeftAdornment: View,
    RightAdornment: View,
    BottomAdornment: View,
    FloatingInfo: View
>:
    View
{
    let uncheckedItems: [Item]
    let checkedItems: [Item]
    let showChecked: Bool
    let floatingInfo: FloatingInfo?
    let customToggleConfig: RowToggleConfig<Item>?
    let checkedHeader: String
    let checkedFooter: String?
    let emptyUncheckedLabel: String
    let emptyCheckedLabel: String
    let namespace: Namespace.ID?
    let tint: (_ item: Item) -> Color
    let toolbarIcons: [String]
    let tapToolbar: ((String, Item) -> Void)?
    let leftAdornment: ((_ item: Item) -> LeftAdornment)?
    let rightAdornment: ((_ item: Item) -> RightAdornment)?
    let bottomAdornment: ((_ item: Item) -> BottomAdornment)?
    let proxy: ScrollViewProxy
    let createItem: (_ baseId: PersistentIdentifier?, _ offset: Int) -> Void
    let handleTitleChange: (_ item: Item) -> Void
    let moveItem: (_ from: Int, _ to: Int) -> Void
    let isItemChecked: ((_ item: Item) -> Bool)?

    @EnvironmentObject private var listManager: ListManager<Item>

    @StateObject var focusController = FocusController()

    var body: some View {
        List {
            Section {
                NewRowTriggerView {
                    createItem(
                        uncheckedItems.first?.id,
                        0
                    )
                }
                .discreetListItem()
                .listRowInsets(EdgeInsets())

                ForEach(uncheckedItems) { item in
                    RowView(
                        item: item,
                        tint: tint,
                        showChecked: showChecked,
                        showUpperDivider: item.id == uncheckedItems.first?.id,
                        toolbarIcons: toolbarIcons,
                        tapToolbar: handleToolbarPress,
                        leftAdornment: leftAdornment,
                        rightAdornment: rightAdornment,
                        bottomAdornment: bottomAdornment,
                        namespace: namespace,
                        customToggleConfig: customToggleConfig,
                        onCreateItem: createItem,
                        onTitleChange: handleTitleChange,
                        isItemChecked: isItemChecked
                    )
                    .id(item.id)
                }
                .onMove(perform: moveUncheckedItem)

                NewRowTriggerView {
                    createItem(uncheckedItems.last?.id, 1)
                }
                .discreetListItem()
                .listRowInsets(EdgeInsets())
                .id("UNCHECKED")

                if uncheckedItems.isEmpty && showChecked {
                    EmptyLabel(emptyUncheckedLabel)
                        .discreetListItem()
                        .frame(maxWidth: .infinity)
                }

            } header: {
                floatingInfo
                    .listRowInsets(.top, 0)
            }
            .listSectionSeparator(.hidden)

            if showChecked {
                Section {
                    ForEach(checkedItems) { item in
                        RowView(
                            item: item,
                            tint: tint,
                            showChecked: true,
                            showUpperDivider: item.id
                                == checkedItems.first?.id,
                            toolbarIcons: toolbarIcons,
                            tapToolbar: { _, _ in },
                            leftAdornment: leftAdornment,
                            rightAdornment: rightAdornment,
                            bottomAdornment: bottomAdornment,
                            namespace: namespace,
                            customToggleConfig: customToggleConfig,
                            onCreateItem: { _, _ in },
                            onTitleChange: { _ in },
                            isItemChecked: isItemChecked
                        )
                    }
                } header: {
                    Text(
                        checkedItems.isEmpty ? emptyCheckedLabel : checkedHeader
                    )
                } footer: {
                    if checkedFooter != nil && !checkedItems.isEmpty {
                        Text(checkedFooter!)
                            .font(.footnote)
                            .foregroundStyle(Color.secondary)
                    }
                }
                .discreetListItem()
                .id("CHECKED")
            }
        }
        .environmentObject(focusController)
        .listStyle(.plain)
        .environment(\.defaultMinListRowHeight, 0)
        .safeAreaPadding(.bottom, 20)
        .background(Color.appBackground.edgesIgnoringSafeArea(.all))
        .overlay {
            if uncheckedItems.isEmpty && !showChecked {
                EmptyLabel(emptyUncheckedLabel)
            }
        }

        // Blur the textfield when the list unmounts (deletes empty items).
        .onDisappear {
            focusController.focusedId = nil
        }
        
        // .animateSynchronousAction(from: uncheckedItems)
        .animateSynchronousAction(from: listManager.newlyCheckedIds)
        .animateSynchronousAction(from: listManager.newlyUncheckedIds)

        // Slide to checked items when the user marks them visible.
        .withScrollTrigger(
            proxy: proxy,
            trigger: showChecked,
            id: "CHECKED",
            disabled: !showChecked
        )
    }

    private func moveUncheckedItem(
        from sources: IndexSet,
        to destination: Int
    ) {
        for source in sources {
            var to = destination

            if to > source {
                to -= 1
            }

            moveItem(source, to)
        }
    }

    private func handleToolbarPress(_ iconName: String, _ item: Item) {
        tapToolbar?(iconName, item)
        focusController.focusedId = nil
        dismissKeyboard()
    }

    func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }

}
