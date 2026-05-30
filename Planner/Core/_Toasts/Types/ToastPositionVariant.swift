//
//  ToastPositionVariant.swift
//  Planner
//
//  Created by Alex Green on 5/25/26.
//
import SwiftUI

enum ToastPositionVariant {
    case cover
    case tab

    var verticalOffset: CGFloat {
        switch self {
        case .cover: return Layout.TOOLBAR_HEIGHT
        case .tab: return 8
        }
    }
}
