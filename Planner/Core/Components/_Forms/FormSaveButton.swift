//
//  FormSaveButton.swift
//  Planner
//
//  Created by Alex Green on 5/22/26.
//

import SwiftUI
import SwiftUIIntrospect

struct FormSaveButtonView: ToolbarContent {
    private let canSave: Bool
    private let save: () -> Void

    init(canSave: Bool, tint: Color? = nil, save: @escaping () -> Void) {
        self.canSave = canSave
        self.save = save

        self.customTint = tint
    }

    private let customTint: Color?

    @AppStorage("accentColor") var accentColor: AccentColor =
        .blue

    var body: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button(
                "FormSaveButton",
                systemImage: "checkmark",
                action: save
            )
            .tint(customTint ?? accentColor.color)
            .disabled(!canSave)
        }
    }
}
