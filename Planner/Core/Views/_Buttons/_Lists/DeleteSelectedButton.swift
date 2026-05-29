//
//  DeleteSelectedButton.swift
//  Planner
//
//  Created by Alex Green on 2/11/26.
//

import SwiftUI

struct DeleteSelectedButtonView<Item: ListItem>: View {
    let confirmationConfig: ConfirmationConfig

    @EnvironmentObject private var listEngine: ListEngine<Item>

    @State private var showConfirmation = false

    // MARK: - Body

    var body: some View {
        GlassIconButtonView(
            systemImageName: "trash",
            disabled: listEngine.selectedItemIds.isEmpty,
            color: Color.label
        ) {
            showConfirmation = true
        }
        .withConfirmation(confirmationConfig, isPresented: $showConfirmation)
    }
}
