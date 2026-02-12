//
//  DeleteSelectedButton.swift
//  Planner
//
//  Created by Alex Green on 2/11/26.
//

import SwiftUI

struct DeleteSelectedButtonView: View {
    let itemsLabel: String
    let disabled: Bool
    let warningMessage: String?
    let onDelete: () -> Void

    @State private var showDeleteSelectedConfirm = false

    private var message: String {
        let baseMessage = "This action is irreversible."

        guard let warningMessage else {
            return baseMessage
        }

        return "\(warningMessage) This action is irreversible."
    }

    var body: some View {
        Button("Delete", systemImage: "trash") {
            showDeleteSelectedConfirm = true
        }
        .disabled(disabled)
        .confirmationDialog(
            "Delete selected \(itemsLabel)?",
            isPresented: $showDeleteSelectedConfirm,
            titleVisibility: .visible
        ) {
            Button("Confirm", role: .destructive, action: onDelete)
        } message: {
            Text(message)
        }
    }
}
