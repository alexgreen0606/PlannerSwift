//
//  DeleteSelectedButton.swift
//  Planner
//
//  Created by Alex Green on 2/11/26.
//

import SwiftUI

// Clean

struct DeleteSelectedButtonView: View {
    let confirmationConfig: ConfirmationConfig
    let disabled: Bool

    @State private var showConfirmation = false

    var body: some View {
        Button("Delete", systemImage: "trash") {
            showConfirmation = true
        }
        .tint(Color.label)
        .disabled(disabled)
        .withConfirmation(confirmationConfig, isPresented: $showConfirmation)
    }
}
