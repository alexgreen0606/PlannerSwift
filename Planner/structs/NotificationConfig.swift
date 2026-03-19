//
//  NotificationConfig.swift
//  Planner
//
//  Created by Alex Green on 3/18/26.
//

import SwiftUI

// Clean

struct NotificationConfig: Equatable {
    let id: UUID
    let title: String
    let subtitle: String?
    let iconConfig: IconConfig
    let onClick: (() -> Void)?

    init(
        id: UUID,
        title: String,
        subtitle: String? = nil,
        iconConfig: IconConfig,
        onClick: (() -> Void)? = nil
    ) {
        self.id = id
        self.title = title
        self.subtitle = subtitle
        self.iconConfig = iconConfig
        self.onClick = onClick
    }

    static func == (lhs: NotificationConfig, rhs: NotificationConfig) -> Bool {
        lhs.id == rhs.id
            && lhs.title == rhs.title
            && lhs.subtitle == rhs.subtitle
    }

}
