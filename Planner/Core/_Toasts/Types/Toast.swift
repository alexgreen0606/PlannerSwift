//
//  Toast.swift
//  Planner
//
//  Created by Alex Green on 3/18/26.
//

import SwiftUI

struct Toast {
    let id = UUID()

    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey?
    let customSubtitle: AnyView?
    let iconConfig: IconConfig
    let variant: ToastPositionVariant
    let action: (() -> Void)?

    init(
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        customSubtitle: AnyView? = nil,
        iconConfig: IconConfig,
        variant: ToastPositionVariant = .cover,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.customSubtitle = customSubtitle
        self.iconConfig = iconConfig
        self.variant = variant
        self.action = action
    }
}
