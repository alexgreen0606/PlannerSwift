//
//  FormSaveButton.swift
//  Planner
//
//  Created by Alex Green on 5/22/26.
//

import SwiftUI

struct FormSaveButtonView: ToolbarContent {
    private let canSave: Bool
    private let save: () -> Void

    init(canSave: Bool = true, tint: Color? = nil, save: @escaping () -> Void) {
        self.canSave = canSave
        self.save = save

        customTint = tint
    }

    private let customTint: Color?

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    // MARK: - Body

    var body: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button(
                "",
                systemImage: "checkmark",
                action: save
            )
            .disabled(!canSave)
            .tint(customTint ?? accentColor.color)
        }
    }
}
