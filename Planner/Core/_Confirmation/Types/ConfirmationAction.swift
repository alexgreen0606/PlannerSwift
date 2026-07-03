//
//  ConfirmationAction.swift
//  Planner
//
//  Created by Alex Green on 2/12/26.
//

import SwiftUI

struct ConfirmationAction: Identifiable {
    let id = UUID()
    let title: LocalizedStringKey
    let role: ButtonRole
    let handler: () -> Void

    init(
        title: LocalizedStringKey,
        role: ButtonRole = .destructive,
        handler: @escaping () -> Void
    ) {
        self.title = title
        self.role = role
        self.handler = handler
    }
}
