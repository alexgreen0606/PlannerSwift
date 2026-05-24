//
//  CreateLowerItemButton.swift
//  Planner
//
//  Created by Alex Green on 5/22/26.
//

import SwiftUI

struct CreateLowerItemButtonView: View {
    private let createItem: () -> Void

    init(tint: Color? = nil, createItem: @escaping () -> Void) {
        self.createItem = createItem

        customTint = tint
    }

    private let customTint: Color?

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    // MARK: - Body

    var body: some View {
        Button("", systemImage: "plus", action: createItem)
            .buttonStyle(.glassProminent)
            .tint(customTint ?? accentColor.color)
    }
}
