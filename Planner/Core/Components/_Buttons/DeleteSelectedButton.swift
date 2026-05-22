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

    var body: some View {
        Button("Delete", systemImage: "trash") {
            showConfirmation = true
        }
        .tint(Color.label)
        .disabled(listEngine.selectedItemIds.isEmpty)
        .withConfirmation(confirmationConfig, isPresented: $showConfirmation)
    }
}
