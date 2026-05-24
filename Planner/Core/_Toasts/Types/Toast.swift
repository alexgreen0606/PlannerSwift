//
//  Toast.swift
//  Planner
//
//  Created by Alex Green on 3/18/26.
//

import SwiftUI

enum ToastVariant {
    case sheet
    case tab

    var trailingPadding: CGFloat {
        switch self {
        case .sheet: return 0 // 68
        case .tab: return 0
        }
    }

    var verticalOffset: CGFloat {
        switch self {
        case .sheet: return 52 // -8
        case .tab: return 8
        }
    }
}

struct Toast {
    let id = UUID()

    let title: LocalizedStringKey
    let subtitle: LocalizedStringKey?
    let iconConfig: IconConfig
    let variant: ToastVariant
    let action: (() -> Void)?

    let customSubtitle: AnyView?

    init(
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey? = nil,
        customSubtitle: AnyView? = nil,
        iconConfig: IconConfig,
        variant: ToastVariant = .sheet,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.customSubtitle = customSubtitle
        self.variant = variant
        self.iconConfig = iconConfig
        self.action = action
    }
}
