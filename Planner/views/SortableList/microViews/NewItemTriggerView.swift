//
//  NewItemTriggerView.swift
//  Planner
//
//  Created by Alex Green on 12/1/25.
//

import SwiftUI

struct NewItemTriggerView: View {
    let showLowerDivider: Bool
    let showUpperDivider: Bool
    let onCreateItem: () -> Void

    init(
        showLowerDivider: Bool = false,
        showUpperDivider: Bool = false,
        onCreateItem: @escaping () -> Void
    ) {
        self.showLowerDivider = showLowerDivider
        self.showUpperDivider = showUpperDivider
        self.onCreateItem = onCreateItem
    }

    var body: some View {
        Rectangle()
            .fill(.clear)
            .frame(height: 8)
            .overlay(
                VStack {
                    if showLowerDivider == true {
                        Spacer()
                        Divider().background(Color(uiColor: .tertiaryLabel))
                    } else if showUpperDivider == true {
                        Divider().background(Color(uiColor: .tertiaryLabel))
                        Spacer()
                    }
                }
            )
            .contentShape(Rectangle())
            .onTapGesture(perform: onCreateItem)
    }
}
