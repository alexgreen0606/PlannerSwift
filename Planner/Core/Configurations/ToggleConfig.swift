//
//  ToggleConfig.swift
//  Planner
//
//  Created by Alex Green on 5/23/26.
//

struct ToggleConfig {
    let pendingIconConfig: IconConfig
    let completedIconConfig: IconConfig
    let confirmation: ConfirmationConfig?
    let onClick: (() -> Void)?

    init(
        pendingIconConfig: IconConfig = IconConfig(name: "circle"),
        completedIconConfig: IconConfig,
        confirmation: ConfirmationConfig? = nil,
        onClick: (() -> Void)? = nil
    ) {
        self.pendingIconConfig = pendingIconConfig
        self.completedIconConfig = completedIconConfig
        self.confirmation = confirmation
        self.onClick = onClick
    }
}
