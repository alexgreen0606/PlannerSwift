//
//  BackButton.swift
//  Planner
//
//  Created by Alex Green on 5/22/26.
//

import SwiftUI

struct BackButtonView: View {
    let handleSideEffects: (() -> Void)?

    init(dismiss: (() -> Void)? = nil, handleSideEffects: (() -> Void)? = nil) {
        self.handleSideEffects = handleSideEffects

        self.customDismiss = dismiss
    }

    private let customDismiss: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        Button(
            "",
            systemImage: "chevron.left"
        ) {
            handleSideEffects?()

            if let customDismiss {
                customDismiss()
            } else {
                dismiss()
            }
        }
        .tint(Color.label)
    }
}
