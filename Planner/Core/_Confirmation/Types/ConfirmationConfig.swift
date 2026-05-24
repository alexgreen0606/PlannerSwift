//
//  ConfirmationConfig.swift
//  Planner
//
//  Created by Alex Green on 5/23/26.
//

struct ConfirmationConfig {
    let title: String
    let message: String
    let actions: [ConfirmationAction]

    init(
        title: String,
        message: String,
        actions: [ConfirmationAction]
    ) {
        self.title = title
        self.message = message
        self.actions = actions
    }
}
