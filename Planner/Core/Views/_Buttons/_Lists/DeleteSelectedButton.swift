//
//  DeleteSelectedButton.swift
//  Planner
//
//  Created by Alex Green on 11/22/26.
//

import SwiftUI

struct DeleteSelectedButtonView<Item: ListItem>: View {
    let confirmationConfig: ConfirmationConfig

    @EnvironmentObject private var listEngine: ListEngine<Item>

    @State private var showConfirmation = false

    // MARK: - Body

    var body: some View {
        GlassIconButtonView(systemImageName: "trash") {
            showConfirmation = true
        }
        .disabled(listEngine.selectedItemIds.isEmpty)
        .withConfirmation(confirmationConfig, isPresented: $showConfirmation)
    }
}
