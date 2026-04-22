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
        case .sheet: return 56
        case .tab: return 0
        }
    }
    
    var verticalOffset: CGFloat {
        switch self {
        case .sheet: return -8
        case .tab: return 60
        }
    }
}

struct Toast {
    let id = UUID()
    
    // Message
    let title: String
    let subtitle: String?
    let iconConfig: IconConfig
    
    // Position
    let variant: ToastVariant
    
    // Action
    let actionText: String?
    let action: (() -> Void)?

    init(
        title: String,
        subtitle: String? = nil,
        variant: ToastVariant = .sheet,
        iconConfig: IconConfig,
        actionText: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.variant = variant
        self.iconConfig = iconConfig
        self.actionText = actionText
        self.action = action
    }
}
