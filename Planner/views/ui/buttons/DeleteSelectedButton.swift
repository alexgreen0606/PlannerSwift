//
//  DeleteSelectedButton.swift
//  Planner
//
//  Created by Alex Green on 2/11/26.
//

import SwiftUI

// Clean

struct DeleteSelectedButtonView: View {
    let itemsLabel: String
    let disabled: Bool
    let message: String?
    let delete: () -> Void

    init(
        itemsLabel: String,
        disabled: Bool,
        message: String? = nil,
        delete: @escaping () -> Void
    ) {
        self.itemsLabel = itemsLabel
        self.disabled = disabled
        self.message = message
        self.delete = delete
    }

    @State private var showConfirmation = false

    private var fullMessage: String {
        let baseMessage = "This action cannot be undone."

        guard let message else {
            return baseMessage
        }

        return "\(message) \(baseMessage)"
    }

    var body: some View {
        Button("Delete", systemImage: "trash") {
            showConfirmation = true
        }
        .disabled(disabled)
        .confirmationDialog(
            "Delete selected \(itemsLabel)?",
            isPresented: $showConfirmation,
            titleVisibility: .visible,
        ) {
            Button("Confirm", role: .destructive, action: delete)
        } message: {
            Text(fullMessage)
        }
    }
}
