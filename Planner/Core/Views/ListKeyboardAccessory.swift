//
//  ListKeyboardAccessory.swift
//  Planner
//
//  Created by Alex Green on 5/29/26.
//

import SwiftUI

struct ListKeyboardAccessoryView<Item: ListItemDetails>: View {
    let items: [Item]
    let iconImageNames: [String]
    let onIconTap: ((String, Item) -> Void)?

    @EnvironmentObject private var listEngine: ListEngine<Item>

    // MARK: - Body

    var body: some View {
        HStack(spacing: 12) {
            Group {
                ForEach(iconImageNames, id: \.self) {
                    systemImageName in
                    Image(systemName: systemImageName)
                        .imageScale(.medium)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            guard let focusedId = listEngine.focusedId,
                                  let item = items.first(where: {
                                      $0.stableId == focusedId
                                  })
                            else { return }

                            listEngine.forceSyncFocusedItem = true
                            onIconTap?(systemImageName, item)
                        }
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
        }
        .glassEffect(.regular.interactive())
        .clipShape(Capsule())
        .contentShape(.capsule)
    }
}
