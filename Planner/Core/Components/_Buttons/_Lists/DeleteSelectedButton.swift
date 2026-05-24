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
        Button("", systemImage: "trash") {
            showConfirmation = true
        }
        .disabled(listEngine.selectedItemIds.isEmpty)
        .tint(Color.label)
        .withConfirmation(confirmationConfig, isPresented: $showConfirmation)
    }
}
