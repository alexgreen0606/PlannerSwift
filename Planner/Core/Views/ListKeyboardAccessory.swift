//
//  ListKeyboardAccessory.swift
//  Planner
//
//  Created by Alex Green on 5/29/26.
//

import SwiftUI

struct ListKeyboardAccessoryView<Item: ListItemDetails>: View {
    let iconImageNames: [String]
    let onIconTap: ((String) -> Void)?

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
                            onIconTap?(systemImageName)
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
