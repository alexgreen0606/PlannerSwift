//
//  DeleteSelectedButton.swift
//  Planner
//
//  Created by Alex Green on 2/11/26.
//

import SwiftUI

// Clean

struct DeleteSelectedButtonView: View {
    let itemLabel: String
    let count: Int
    let message: String?
    let delete: () -> Void

    init(
        itemLabel: String,
        count: Int,
        message: String? = nil,
        delete: @escaping () -> Void
    ) {
        self.itemLabel = itemLabel
        self.count = count
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
        .tint(Color.label)
        .disabled(count == 0)
        .confirmationDialog(
            "Delete \(count > 1 ? "\(count) \(itemLabel)s" : itemLabel)?",
            isPresented: $showConfirmation,
            titleVisibility: .visible,
        ) {
            Button(
                "Delete\(count > 1 ? " \(count)" : "") \(itemLabel.pluralized(from: count).capitalizedFirst)",
                role: .destructive,
                action: delete
            )
        } message: {
            Text(fullMessage)
        }
    }
}
