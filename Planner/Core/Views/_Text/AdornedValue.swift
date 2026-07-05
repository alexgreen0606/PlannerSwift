//
//  AdornedValue.swift
//  Planner
//
//  Created by Alex Green on 4/1/26.
//

import SwiftUI

struct AdornedValue: View {
    private let text: String
    private let iconConfig: IconConfig?
    private let color: Color?
    private let scale: Double

    init(
        _ text: String,
        iconConfig: IconConfig? = nil,
        color: Color? = nil,
        scale: Double = 1
    ) {
        self.text = text
        self.iconConfig = iconConfig
        self.color = color
        self.scale = scale
    }

    private var iconSize: CGFloat {
        Layout.TEXT * scale
    }

    // MARK: - Body

    var body: some View {
        HStack(spacing: Layout.DEFAULT_ADORNMENT_SPACING * scale) {
            if let iconConfig {
                Image(systemName: iconConfig.name)
                    .foregroundStyle(
                        iconConfig.primaryColor,
                        iconConfig.secondaryColor
                    )
            }

            Value(text, color: color, scale: scale)
        }
        .font(.system(size: iconSize, weight: .regular))
    }
}
