//
//  ConfirmationAction.swift
//  Planner
//
//  Created by Alex Green on 2/12/26.
//

import SwiftUI

struct ConfirmationAction {
    let title: String
    let role: ButtonRole
    let handler: () -> Void

    init(
        title: String,
        role: ButtonRole = .destructive,
        handler: @escaping () -> Void
    ) {
        self.title = title
        self.role = role
        self.handler = handler
    }
}
