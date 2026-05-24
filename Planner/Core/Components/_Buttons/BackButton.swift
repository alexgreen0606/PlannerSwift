//
//  BackButton.swift
//  Planner
//
//  Created by Alex Green on 5/22/26.
//

import SwiftUI

struct BackButtonView: View {
    let handleSideEffects: (() -> Void)?

    init(handleSideEffects: (() -> Void)? = nil) {
        self.handleSideEffects = handleSideEffects
    }

    @Environment(\.dismiss) private var dismiss

    // MARK: - Body

    var body: some View {
        Button(
            "",
            systemImage: "chevron.left"
        ) {
            handleSideEffects?()
            dismiss()
        }
        .tint(Color.label)
    }
}
